
local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 81) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 68) then
					if (Enum <= 33) then
						if (Enum <= 16) then
							if (Enum <= 7) then
								if (Enum <= 3) then
									if (Enum <= 1) then
										if (Enum == 0) then
											local K;
											local B;
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											B = Inst[3];
											K = Stk[B];
											for Idx = B + 1, Inst[4] do
												K = K .. Stk[Idx];
											end
											Stk[Inst[2]] = K;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											B = Inst[3];
											K = Stk[B];
											for Idx = B + 1, Inst[4] do
												K = K .. Stk[Idx];
											end
											Stk[Inst[2]] = K;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = {};
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Inst[3]] = Inst[4];
										else
											local A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
									elseif (Enum > 2) then
										local A = Inst[2];
										local Results = {Stk[A](Stk[A + 1])};
										local Edx = 0;
										for Idx = A, Inst[4] do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Top));
									end
								elseif (Enum <= 5) then
									if (Enum > 4) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A]();
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
									end
								elseif (Enum > 6) then
									Stk[Inst[2]] = Stk[Inst[3]] - Inst[4];
								else
									local A = Inst[2];
									local Results = {Stk[A]()};
									local Limit = Inst[4];
									local Edx = 0;
									for Idx = A, Limit do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								end
							elseif (Enum <= 11) then
								if (Enum <= 9) then
									if (Enum > 8) then
										local B;
										local A;
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									else
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A], Stk[A + 1];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum > 10) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
								end
							elseif (Enum <= 13) then
								if (Enum > 12) then
									do
										return Stk[Inst[2]];
									end
								else
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return Stk[Inst[2]];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 14) then
								local A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
							elseif (Enum == 15) then
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							else
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return Stk[Inst[2]];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 24) then
							if (Enum <= 20) then
								if (Enum <= 18) then
									if (Enum > 17) then
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									else
										local A = Inst[2];
										Stk[A] = Stk[A]();
									end
								elseif (Enum == 19) then
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								else
									local T;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									T = Stk[A];
									B = Inst[3];
									for Idx = 1, B do
										T[Idx] = Stk[A + Idx];
									end
								end
							elseif (Enum <= 22) then
								if (Enum > 21) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A]());
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local B;
									local A;
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum == 23) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A;
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 28) then
							if (Enum <= 26) then
								if (Enum > 25) then
									local Edx;
									local Results, Limit;
									local B;
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								end
							elseif (Enum == 27) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return Stk[Inst[2]];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							else
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
							end
						elseif (Enum <= 30) then
							if (Enum == 29) then
								local B;
								local T;
								local A;
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								T = Stk[A];
								B = Inst[3];
								for Idx = 1, B do
									T[Idx] = Stk[A + Idx];
								end
							elseif (Stk[Inst[2]] ~= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						elseif (Enum <= 31) then
							Stk[Inst[2]] = #Stk[Inst[3]];
						elseif (Enum > 32) then
							if (Stk[Inst[2]] ~= Inst[4]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results, Limit;
							local B;
							local A;
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Env[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Env[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Env[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]]();
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						end
					elseif (Enum <= 50) then
						if (Enum <= 41) then
							if (Enum <= 37) then
								if (Enum <= 35) then
									if (Enum > 34) then
										Stk[Inst[2]]();
									else
										local Edx;
										local Results;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results = {Stk[A](Stk[A + 1])};
										Edx = 0;
										for Idx = A, Inst[4] do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if Stk[Inst[2]] then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									end
								elseif (Enum > 36) then
									local B;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								else
									Stk[Inst[2]] = Stk[Inst[3]] % Inst[4];
								end
							elseif (Enum <= 39) then
								if (Enum == 38) then
									local Step;
									local Index;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = #Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Index = Stk[A];
									Step = Stk[A + 2];
									if (Step > 0) then
										if (Index > Stk[A + 1]) then
											VIP = Inst[3];
										else
											Stk[A + 3] = Index;
										end
									elseif (Index < Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum > 40) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 45) then
							if (Enum <= 43) then
								if (Enum > 42) then
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum == 44) then
								Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
							else
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return Stk[Inst[2]];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 47) then
							if (Enum == 46) then
								local Edx;
								local Results, Limit;
								local B;
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							else
								local B;
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 48) then
							local A = Inst[2];
							Stk[A](Stk[A + 1]);
						elseif (Enum == 49) then
							local Results;
							local Edx;
							local Results, Limit;
							local B;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Unpack(Stk, A + 1, Top))};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						else
							local B;
							local A;
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						end
					elseif (Enum <= 59) then
						if (Enum <= 54) then
							if (Enum <= 52) then
								if (Enum > 51) then
									local B;
									local A;
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								else
									local A;
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum == 53) then
								if (Stk[Inst[2]] < Stk[Inst[4]]) then
									VIP = Inst[3];
								else
									VIP = VIP + 1;
								end
							else
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 56) then
							if (Enum > 55) then
								local B;
								local A;
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A]();
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 57) then
							local Results;
							local Edx;
							local Results, Limit;
							local B;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Unpack(Stk, A + 1, Top))};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						elseif (Enum == 58) then
							local B;
							local A;
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results;
							local B;
							local A;
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							B = Stk[Inst[4]];
							if not B then
								VIP = VIP + 1;
							else
								Stk[Inst[2]] = B;
								VIP = Inst[3];
							end
						end
					elseif (Enum <= 63) then
						if (Enum <= 61) then
							if (Enum > 60) then
								local A = Inst[2];
								local Index = Stk[A];
								local Step = Stk[A + 2];
								if (Step > 0) then
									if (Index > Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Index < Stk[A + 1]) then
									VIP = Inst[3];
								else
									Stk[A + 3] = Index;
								end
							else
								local A = Inst[2];
								do
									return Stk[A], Stk[A + 1];
								end
							end
						elseif (Enum > 62) then
							local A = Inst[2];
							local Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
							local Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
						else
							do
								return;
							end
						end
					elseif (Enum <= 65) then
						if (Enum == 64) then
							local B;
							local A;
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						elseif (Stk[Inst[2]] == Stk[Inst[4]]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					elseif (Enum <= 66) then
						local B;
						local A;
						A = Inst[2];
						B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
					elseif (Enum == 67) then
						Stk[Inst[2]] = Inst[3];
					else
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return Stk[Inst[2]];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return;
						end
					end
				elseif (Enum <= 103) then
					if (Enum <= 85) then
						if (Enum <= 76) then
							if (Enum <= 72) then
								if (Enum <= 70) then
									if (Enum == 69) then
										Stk[Inst[2]] = Env[Inst[3]];
									else
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									end
								elseif (Enum == 71) then
									if (Stk[Inst[2]] > Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = VIP + Inst[3];
									end
								elseif not Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum <= 74) then
								if (Enum == 73) then
									local A = Inst[2];
									local Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									local Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								else
									Env[Inst[3]] = Stk[Inst[2]];
								end
							elseif (Enum > 75) then
								local B = Stk[Inst[4]];
								if not B then
									VIP = VIP + 1;
								else
									Stk[Inst[2]] = B;
									VIP = Inst[3];
								end
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum <= 80) then
							if (Enum <= 78) then
								if (Enum == 77) then
									local Step;
									local Index;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A]();
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = #Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Index = Stk[A];
									Step = Stk[A + 2];
									if (Step > 0) then
										if (Index > Stk[A + 1]) then
											VIP = Inst[3];
										else
											Stk[A + 3] = Index;
										end
									elseif (Index < Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								else
									local B;
									local A;
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum == 79) then
								Upvalues[Inst[3]] = Stk[Inst[2]];
							else
								local Step;
								local Index;
								local A;
								A = Inst[2];
								Stk[A] = Stk[A]();
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = #Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Index = Stk[A];
								Step = Stk[A + 2];
								if (Step > 0) then
									if (Index > Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Index < Stk[A + 1]) then
									VIP = Inst[3];
								else
									Stk[A + 3] = Index;
								end
							end
						elseif (Enum <= 82) then
							if (Enum > 81) then
								local Edx;
								local Results;
								local B;
								local A;
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								B = Stk[Inst[4]];
								if not B then
									VIP = VIP + 1;
								else
									Stk[Inst[2]] = B;
									VIP = Inst[3];
								end
							else
								local A;
								Env[Inst[3]] = Stk[Inst[2]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
							end
						elseif (Enum <= 83) then
							local B;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						elseif (Enum > 84) then
							if (Inst[2] <= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							Stk[Inst[2]] = {};
						end
					elseif (Enum <= 94) then
						if (Enum <= 89) then
							if (Enum <= 87) then
								if (Enum > 86) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Stk[Inst[2]] <= Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 88) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 91) then
							if (Enum > 90) then
								local A = Inst[2];
								local Results, Limit = _R(Stk[A]());
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							else
								Stk[Inst[2]][Inst[3]] = Inst[4];
							end
						elseif (Enum <= 92) then
							local B;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						elseif (Enum > 93) then
							local A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						else
							local B;
							local A;
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						end
					elseif (Enum <= 98) then
						if (Enum <= 96) then
							if (Enum > 95) then
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							else
								local B;
								local A;
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							end
						elseif (Enum == 97) then
							local Edx;
							local Results, Limit;
							local B;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]]();
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						else
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return Stk[Inst[2]];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						end
					elseif (Enum <= 100) then
						if (Enum == 99) then
							local Edx;
							local Results;
							local A;
							Upvalues[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Stk[A + 1])};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if not Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						elseif (Stk[Inst[2]] < Stk[Inst[4]]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					elseif (Enum <= 101) then
						Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
					elseif (Enum > 102) then
						local K;
						local B;
						Stk[Inst[2]] = {};
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						B = Inst[3];
						K = Stk[B];
						for Idx = B + 1, Inst[4] do
							K = K .. Stk[Idx];
						end
						Stk[Inst[2]] = K;
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						B = Inst[3];
						K = Stk[B];
						for Idx = B + 1, Inst[4] do
							K = K .. Stk[Idx];
						end
						Stk[Inst[2]] = K;
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = {};
					else
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Inst[3]] = Inst[4];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return;
						end
					end
				elseif (Enum <= 120) then
					if (Enum <= 111) then
						if (Enum <= 107) then
							if (Enum <= 105) then
								if (Enum == 104) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								else
									local A = Inst[2];
									local C = Inst[4];
									local CB = A + 2;
									local Result = {Stk[A](Stk[A + 1], Stk[CB])};
									for Idx = 1, C do
										Stk[CB + Idx] = Result[Idx];
									end
									local R = Result[1];
									if R then
										Stk[CB] = R;
										VIP = Inst[3];
									else
										VIP = VIP + 1;
									end
								end
							elseif (Enum > 106) then
								local NewProto = Proto[Inst[3]];
								local NewUvals;
								local Indexes = {};
								NewUvals = Setmetatable({}, {__index=function(_, Key)
									local Val = Indexes[Key];
									return Val[1][Val[2]];
								end,__newindex=function(_, Key, Value)
									local Val = Indexes[Key];
									Val[1][Val[2]] = Value;
								end});
								for Idx = 1, Inst[4] do
									VIP = VIP + 1;
									local Mvm = Instr[VIP];
									if (Mvm[1] == 110) then
										Indexes[Idx - 1] = {Stk,Mvm[3]};
									else
										Indexes[Idx - 1] = {Upvalues,Mvm[3]};
									end
									Lupvals[#Lupvals + 1] = Indexes;
								end
								Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
							else
								local A;
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 109) then
							if (Enum == 108) then
								Stk[Inst[2]] = Stk[Inst[3]] - Stk[Inst[4]];
							else
								local A = Inst[2];
								local T = Stk[A];
								for Idx = A + 1, Inst[3] do
									Insert(T, Stk[Idx]);
								end
							end
						elseif (Enum > 110) then
							Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
						else
							Stk[Inst[2]] = Stk[Inst[3]];
						end
					elseif (Enum <= 115) then
						if (Enum <= 113) then
							if (Enum > 112) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return Stk[Inst[2]];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							else
								local A = Inst[2];
								do
									return Unpack(Stk, A, A + Inst[3]);
								end
							end
						elseif (Enum == 114) then
							local Edx;
							local Results, Limit;
							local B;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]]();
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						else
							local A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
						end
					elseif (Enum <= 117) then
						if (Enum == 116) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A]();
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A]();
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local B;
							local A;
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
						end
					elseif (Enum <= 118) then
						VIP = Inst[3];
					elseif (Enum > 119) then
						local A = Inst[2];
						local T = Stk[A];
						local B = Inst[3];
						for Idx = 1, B do
							T[Idx] = Stk[A + Idx];
						end
					else
						local A = Inst[2];
						Stk[A](Unpack(Stk, A + 1, Top));
					end
				elseif (Enum <= 129) then
					if (Enum <= 124) then
						if (Enum <= 122) then
							if (Enum == 121) then
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return Stk[Inst[2]];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							else
								local B = Inst[3];
								local K = Stk[B];
								for Idx = B + 1, Inst[4] do
									K = K .. Stk[Idx];
								end
								Stk[Inst[2]] = K;
							end
						elseif (Enum > 123) then
							if (Stk[Inst[2]] < Inst[4]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local B;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Inst[4];
						end
					elseif (Enum <= 126) then
						if (Enum == 125) then
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A]();
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
						end
					elseif (Enum <= 127) then
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return Stk[Inst[2]];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return;
						end
					elseif (Enum == 128) then
						Stk[Inst[2]] = Inst[3] ~= 0;
					else
						local B;
						local A;
						A = Inst[2];
						B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Stk[A + 1]);
						VIP = VIP + 1;
						Inst = Instr[VIP];
						if not Stk[Inst[2]] then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					end
				elseif (Enum <= 133) then
					if (Enum <= 131) then
						if (Enum == 130) then
							local B;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return Stk[Inst[2]];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						else
							local A = Inst[2];
							local Step = Stk[A + 2];
							local Index = Stk[A] + Step;
							Stk[A] = Index;
							if (Step > 0) then
								if (Index <= Stk[A + 1]) then
									VIP = Inst[3];
									Stk[A + 3] = Index;
								end
							elseif (Index >= Stk[A + 1]) then
								VIP = Inst[3];
								Stk[A + 3] = Index;
							end
						end
					elseif (Enum > 132) then
						Stk[Inst[2]] = Upvalues[Inst[3]];
					else
						local A = Inst[2];
						local Results = {Stk[A](Unpack(Stk, A + 1, Top))};
						local Edx = 0;
						for Idx = A, Inst[4] do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
					end
				elseif (Enum <= 135) then
					if (Enum == 134) then
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						if (Stk[Inst[2]] == Stk[Inst[4]]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					else
						local A = Inst[2];
						local B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
					end
				elseif (Enum <= 136) then
					local B;
					local A;
					A = Inst[2];
					B = Stk[Inst[3]];
					Stk[A + 1] = B;
					Stk[A] = B[Inst[4]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Stk[Inst[3]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Env[Inst[3]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = {};
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]][Inst[3]] = Inst[4];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					Stk[A] = Stk[A](Stk[A + 1]);
					VIP = VIP + 1;
					Inst = Instr[VIP];
					do
						return;
					end
				elseif (Enum == 137) then
					local A = Inst[2];
					local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
					Top = (Limit + A) - 1;
					local Edx = 0;
					for Idx = A, Top do
						Edx = Edx + 1;
						Stk[Idx] = Results[Edx];
					end
				else
					local Edx;
					local Results, Limit;
					local B;
					local A;
					Stk[Inst[2]] = Env[Inst[3]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Env[Inst[3]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					B = Stk[Inst[3]];
					Stk[A + 1] = B;
					Stk[A] = B[Inst[4]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Inst[3];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
					Top = (Limit + A) - 1;
					Edx = 0;
					for Idx = A, Top do
						Edx = Edx + 1;
						Stk[Idx] = Results[Edx];
					end
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]]();
					VIP = VIP + 1;
					Inst = Instr[VIP];
					do
						return;
					end
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!693Q00030A3Q006C6F6164737472696E6703043Q0067616D6503073Q00482Q747047657403483Q00682Q7470733A2Q2F7261772E67697468756275736572636F6E74656E742E636F6D2F7848657074632F4B61766F2D55492D4C6962726172792F6D61696E2F736F757263652E6C756103093Q004372656174654C6962030C3Q00F09F94B04D4158492048554203083Q004D69646E6967687403063Q004E657754616203163Q004275696C6420746F204265636F6D6520536E69706572030A3Q004E657753656374696F6E030B3Q004175746F2042727564676503073Q00506C6179657273030B3Q004C6F63616C506C61796572026Q000840025Q00207D40030E3Q00436861726163746572412Q64656403073Q00436F2Q6E65637403093Q004E6577546F2Q676C65030C3Q004175746F2062726964676573031F3Q004175746F2074656C65706F7274206163726F2Q732074686520627269646765030A3Q00536E6970657244656164032E3Q00536E697065722044656164202864696520617420352Q3020626C6F636B7320616E64207374617274206F76657229030C3Q004175746F2052656269727468030B3Q004175746F52656269727468032C3Q004175746F207265626972746820287768656E204B692Q6C7320726571756972656D656E74206973206D657429030E3Q004175746F204275792043612Q727903043Q006E616D6503013Q003203053Q007072696365026Q00244003013Q0033026Q00494003013Q0034026Q00694003013Q0035025Q00408F4003013Q0036025Q0088B340030C3Q004175746F42757943612Q727903203Q004175746F20627579202B206175746F20657175697020626573742043612Q727903093Q00556E6976657273616C03093Q004E6577536C6964657203093Q0057616C6B53702Q656403113Q004368616E6765732057616C6B53702Q6564025Q00407F40026Q00304003093Q004A756D70506F77657203113Q004368616E676573204A756D70506F77657203093Q004E657742752Q746F6E030D3Q00496E66696E697465206A756D702Q033Q003Q3F03053Q00526573657403063Q0052656A6F696E03103Q00556E6976657273616C20536372697074030B3Q005549206B6579626F61726403073Q004F6E6C7920504303083Q00616E74692041464B03173Q004E6F206B69636B20666F72203230206D696E2E2041464B03103Q00416E6974436865617420427970612Q73031F3Q00576F726B7320696E206D6F73742067616D657320627574206E6F7420612Q6C03093Q00554E4320436865636B031B3Q00436865636B7320554E43206F6620796F757220696E6A6563746F7203083Q0053652Q74696E6773030E3Q0053652Q74696E677320636C6F7365030A3Q004E65774B657962696E6403093Q00546F2Q676C65205549030B3Q00546F2Q676C65277320554903043Q00456E756D03073Q004B6579436F6465030C3Q005269676874436F6E74726F6C03073Q004372656469747303113Q004D616465204279206D61786B697469303103103Q0054656C656772616D206368612Q6E656C030A3Q004765745365727669636503103Q0055736572496E70757453657276696365030B3Q00476574506C6174666F726D03043Q006162616203073Q00414E44524F494403023Q00504303053Q004A6F624964030B3Q0053656E644D652Q7361676503103Q0053656E644D652Q73616765454D42454403793Q00682Q7470733A2Q2F646973636F72642E636F6D2F6170692F776562682Q6F6B732F313238313235302Q363335342Q3739373537362F2D674B4C57477030426D2D77706E492D4F656C6B354166504777745154676B2Q695342674A764E6250555044384F6E2D516250394D4F4944364E556E4E4764635F39713003053Q007469746C6503233Q00D090D0BAD182D0B8D0B2D0B8D180D0BED0B2D0B0D0BD20D181D0BAD180D0B8D0BFD182030B3Q006465736372697074696F6E03013Q002E03053Q00636F6C6F72024Q006069F84003063Q006669656C6473030D3Q00446973706C61794E616D653A20030B3Q00446973706C61794E616D6503053Q0076616C756503063Q004E616D653A2003043Q004E616D6503013Q002D034Q0003043Q0049443A2003063Q0055736572496403073Q006A6F6249643A2003083Q004578656375746F72030E3Q00D097D0B0D188D0B5D0BB20D1812003063Q00662Q6F74657203043Q0074657874031F3Q00D092D0B0D18820D0BBD18ED0B1D18BD0BCD18BD0B93A204D41584920485542004D012Q00121A3Q00013Q00122Q000100023Q00202Q00010001000300122Q000300046Q000100039Q0000026Q0001000200202Q00013Q000500122Q000200063Q00122Q000300074Q000100010003000200203400020001000800122Q000400096Q00020004000200202Q00030002000A00122Q0005000B6Q00030005000200122Q000400023Q00202Q00040004000C00202Q00040004000D00066B00053Q000100012Q006E3Q00043Q00066B00060001000100012Q006E3Q00053Q00066B00070002000100012Q006E3Q00043Q00066B00080003000100012Q006E3Q00073Q00066B00090004000100012Q006E3Q00073Q00066B000A0005000100012Q006E3Q00063Q00066B000B0006000100012Q006E3Q00063Q00026F000C00073Q00066B000D0008000100022Q006E3Q00064Q006E3Q000C3Q001243000E000E3Q001243000F000F3Q00066B00100009000100032Q006E3Q000D4Q006E3Q000F4Q006E3Q000E3Q00066B0011000A000100012Q006E3Q00043Q00066B0012000B000100012Q006E3Q00113Q00026F0013000C4Q008000146Q008000156Q008000166Q008000175Q00066B0018000D0001000B2Q006E3Q00174Q006E3Q00154Q006E3Q00144Q006E3Q00124Q006E3Q00164Q006E3Q00084Q006E3Q00134Q006E3Q00094Q006E3Q000B4Q006E3Q000A4Q006E3Q00103Q00206000190004001000208700190019001100066B001B000E000100022Q006E3Q00154Q006E3Q00184Q00730019001B0001002087001900030012001243001B00133Q001243001C00143Q00066B001D000F000100022Q006E3Q00154Q006E3Q00184Q00730019001D0001002087001900030012001243001B00153Q001243001C00163Q00066B001D0010000100012Q006E3Q00164Q00730019001D000100208700190002000A001243001B00174Q00010019001B000200066B001A0011000100012Q006E3Q00043Q00066B001B0012000100012Q006E3Q001A3Q00066B001C0013000100012Q006E3Q00044Q0080001D6Q0080001E5Q00066B001F0014000100042Q006E3Q001E4Q006E3Q001D4Q006E3Q001B4Q006E3Q001C3Q002087002000190012001243002200183Q001243002300193Q00066B00240015000100022Q006E3Q001D4Q006E3Q001F4Q007500200024000100202Q00200002000A00122Q0022001A6Q0020002200024Q002100056Q00223Q000200302Q0022001B001C00302Q0022001D001E4Q00233Q000200302Q0023001B001F00305A0023001D00202Q001D00243Q000200302Q0024001B002100302Q0024001D00224Q00253Q000200302Q0025001B002300302Q0025001D00244Q00263Q000200302Q0026001B002500302Q0026001D00264Q00210005000100066B00220016000100012Q006E3Q00043Q00066B00230017000100012Q006E3Q00063Q00066B00240018000100012Q006E3Q00063Q00026F002500193Q00066B0026001A000100022Q006E3Q00084Q006E3Q00253Q00066B0027001B000100042Q006E3Q00224Q006E3Q00214Q006E3Q00234Q006E3Q00263Q00066B0028001C000100042Q006E3Q00214Q006E3Q00234Q006E3Q00244Q006E3Q00254Q008000296Q0080002A5Q00066B002B001D000100092Q006E3Q002A4Q006E3Q00294Q006E3Q00224Q006E3Q00214Q006E3Q00234Q006E3Q00244Q006E3Q00144Q006E3Q00274Q006E3Q00283Q002087002C00200012001243002E00273Q001243002F00283Q00066B0030001E000100022Q006E3Q00294Q006E3Q002B4Q005F002C0030000100202Q002C0001000800122Q002E00296Q002C002E000200202Q002D002C000A00122Q002F00296Q002D002F000200202Q002E002D002A00122Q0030002B3Q00122Q0031002C3Q0012430032002D3Q0012430033002E3Q00026F0034001F4Q004E002E0034000100202Q002E002D002A00122Q0030002F3Q00122Q003100303Q00122Q0032002D3Q00122Q003300203Q00026F003400204Q0073002E00340001002087002E002D0031001243003000323Q001243003100333Q00026F003200214Q0073002E00320001002087002E002D0031001243003000343Q001243003100333Q00026F003200224Q0073002E00320001002087002E002D0031001243003000353Q001243003100333Q00026F003200234Q005D002E0032000100202Q002E002C000A00122Q003000366Q002E0030000200202Q002F002E003100122Q003100373Q00122Q003200383Q00026F003300244Q0073002F00330001002087002F002E0031001243003100393Q0012430032003A3Q00026F003300254Q0073002F00330001002087002F002E00310012430031003B3Q0012430032003C3Q00026F003300264Q0073002F00330001002087002F002E00310012430031003D3Q0012430032003E3Q00026F003300274Q005F002F0033000100202Q002F0001000800122Q0031003F6Q002F0031000200202Q0030002F000A00122Q003200406Q00300032000200202Q00310030004100122Q003300423Q00122Q003400433Q001245003500443Q00206000350035004500206000350035004600066B00360028000100012Q006E8Q005F00310036000100202Q00310001000800122Q003300476Q00310033000200202Q00320031000A00122Q003400476Q00320034000200202Q00330032003100122Q003500483Q00122Q003600493Q00026F003700294Q003800330037000100122Q003300023Q00202Q00330033004A00122Q0035004B6Q00330035000200202Q00340033004C4Q00340002000200066B0035002A000100012Q006E3Q00344Q006E003600354Q001100360001000200062B003600092Q013Q0004763Q00092Q010012430036004E3Q00124A0036004D3Q0004763Q000B2Q010012430036004F3Q00124A0036004D3Q001245003600023Q00204200360036004A00122Q0038000C6Q00360038000200202Q00370036000D00122Q003800023Q00202Q00380038005000026F0039002B3Q00026F003A002C3Q00124A003A00513Q00026F003A002D3Q001251003A00523Q00122Q003A00533Q00122Q003B00516Q003C003A6Q003B000200014Q003B3Q000500302Q003B0054005500302Q003B0056005700302Q003B005800594Q003C00064Q0054003D3Q000200122Q003E005B3Q00202Q003F0037005C4Q003E003E003F00102Q003D001B003E00122Q003E005E3Q00202Q003F0037005F4Q003E003E003F00102Q003D005D003E4Q003E3Q000200302Q003E001B006000305A003E005D00612Q0067003F3Q000200122Q004000623Q00202Q0041003700634Q00400040004100102Q003F001B004000122Q004000646Q004100386Q00400040004100102Q003F005D00404Q00403Q000200305A0040001B00652Q000A004100396Q00410001000200102Q0040005D00414Q00413Q000200302Q0041001B006000302Q0041005D00614Q00423Q000200302Q0042001B006100122Q004300663Q00122Q0044004D4Q007A0043004300440010460042005D00432Q0078003C00060001001046003B005A003C2Q006A003C3Q000100302Q003C0068006900102Q003B0067003C00122Q003C00526Q003D003A6Q003E003B6Q003C003E00016Q00013Q002E3Q00073Q0003063Q0069706169727303093Q00776F726B737061636503053Q00506C6F7473030B3Q004765744368696C6472656E030E3Q0046696E6446697273744368696C6403063Q00506C6179657203053Q0056616C756500163Q0012393Q00013Q00122Q000100023Q00202Q00010001000300202Q0001000100044Q000100029Q00000200044Q00110001002087000500040005001243000700064Q000100050007000200062B0005001100013Q0004763Q001100010020600006000500072Q008500075Q00064100060011000100070004763Q001100012Q000D000400023Q0006693Q0007000100020004763Q000700012Q00048Q000D3Q00024Q003E3Q00017Q00043Q00026Q00244003043Q007469636B03043Q0077616974026Q00E03F01163Q0006483Q0003000100010004763Q000300010012433Q00013Q001245000100024Q0011000100010002001245000200024Q00110002000100022Q006C0002000200010006640002001300013Q0004763Q001300012Q008500026Q001100020001000200062B0002000F00013Q0004763Q000F00012Q000D000200023Q001245000300033Q001243000400044Q00300003000200010004763Q000500012Q0004000200024Q000D000200024Q003E3Q00017Q00063Q0003093Q00436861726163746572030E3Q00436861726163746572412Q64656403043Q0057616974030C3Q0057616974466F724368696C6403103Q0048756D616E6F6964522Q6F7450617274026Q00144000104Q00857Q0020605Q00010006483Q0008000100010004763Q000800012Q00857Q0020605Q00020020875Q00032Q000E3Q0002000200208700013Q0004001208000300053Q00122Q000400066Q0001000400024Q000200016Q00038Q000200038Q00017Q00063Q0003073Q00566563746F72332Q033Q006E6577028Q00026Q00084003063Q00434672616D6503083Q00506F736974696F6E02173Q0006483Q0003000100010004763Q000300012Q003E3Q00013Q0006480001000C000100010004763Q000C0001001245000200013Q00206800020002000200122Q000300033Q00122Q000400043Q00122Q000500036Q0002000500024Q000100024Q008500026Q001100020001000200062B0002001600013Q0004763Q00160001001245000300053Q00200B00030003000200202Q00043Q00064Q0004000400014Q00030002000200102Q0002000500032Q003E3Q00017Q00043Q0003153Q0046696E6446697273744368696C644F66436C612Q7303083Q0048756D616E6F696403063Q004865616C7468029Q000B4Q00858Q00063Q0001000100062B0001000A00013Q0004763Q000A0001002087000200010001001243000400024Q000100020004000200062B0002000A00013Q0004763Q000A000100305A0002000300042Q003E3Q00017Q00013Q0003053Q007063612Q6C00114Q00858Q00113Q000100020006483Q0006000100010004763Q000600012Q0004000100014Q000D000100023Q001245000100013Q00066B00023Q000100012Q006E8Q000300010002000200062B0001000E00013Q0004763Q000E000100064C0003000F000100020004763Q000F00012Q0004000300034Q000D000300024Q003E3Q00013Q00013Q00033Q0003043Q004D69736303083Q00706C6174666F726D03043Q006E656F6E00064Q002D7Q00206Q000100206Q000200206Q00036Q00028Q00017Q00013Q0003053Q007063612Q6C00114Q00858Q00113Q000100020006483Q0006000100010004763Q000600012Q0004000100014Q000D000100023Q001245000100013Q00066B00023Q000100012Q006E8Q000300010002000200062B0001000E00013Q0004763Q000E000100064C0003000F000100020004763Q000F00012Q0004000300034Q000D000300024Q003E3Q00013Q00013Q00033Q0003043Q004D69736303063Q0067726F756E6403083Q00544553542E30323500064Q002D7Q00206Q000100206Q000200206Q00036Q00028Q00017Q00043Q00025Q00407F40026Q002440028Q00026Q00F03F010D3Q0026273Q0004000100010004763Q000400012Q008000016Q000D000100023Q00202400013Q00020026210001000A000100030004763Q000A00010026210001000A000100040004763Q000A00012Q001C00026Q0080000200014Q000D000200024Q003E3Q00017Q000C3Q0003053Q007063612Q6C03063Q00697061697273030B3Q004765744368696C6472656E2Q033Q0049734103083Q00426173655061727403083Q00746F6E756D62657203043Q004E616D6503053Q007461626C6503063Q00696E7365727403043Q00706172742Q033Q006E756D03043Q00736F727400354Q00858Q00113Q000100020006483Q0006000100010004763Q000600012Q005400016Q000D000100023Q001245000100013Q00066B00023Q000100012Q006E8Q000300010002000200062B0001000E00013Q0004763Q000E000100064800020010000100010004763Q001000012Q005400036Q000D000300024Q005400035Q001231000400023Q00202Q0005000200034Q000500066Q00043Q000600044Q002C0001002087000900080004001243000B00054Q00010009000B000200062B0009002C00013Q0004763Q002C0001001245000900063Q002060000A000800072Q000E00090002000200062B0009002C00013Q0004763Q002C00012Q0085000A00014Q006E000B00094Q000E000A00020002000648000A002C000100010004763Q002C0001001245000A00083Q00204B000A000A00094Q000B00036Q000C3Q000200102Q000C000A000800102Q000C000B00094Q000A000C000100066900040016000100020004763Q00160001001245000400083Q00206000040004000C2Q006E000500033Q00026F000600014Q00730004000600012Q000D000300024Q003E3Q00013Q00023Q00013Q0003063Q0042726964676500044Q00857Q0020605Q00012Q000D3Q00024Q003E3Q00017Q00013Q002Q033Q006E756D02083Q00206000023Q000100206000030001000100063500020005000100030004763Q000500012Q001C00026Q0080000200014Q000D000200024Q003E3Q00017Q00083Q00028Q0003063Q006970616972732Q033Q006E756D03053Q007461626C6503063Q00696E7365727403043Q0070617274030C3Q005472616E73706172656E6379026Q00F03F003A4Q00858Q00113Q000100022Q001F00015Q00262700010007000100010004763Q000700012Q0004000100014Q000D000100024Q005400015Q001245000200024Q006E00036Q00030002000200040004763Q001500010020600007000600032Q0085000800013Q00065600070015000100080004763Q00150001001245000700043Q0020600007000700052Q006E000800014Q006E000900064Q00730007000900010006690002000C000100020004763Q000C00012Q001F000200013Q0026270002001C000100010004763Q001C00012Q0004000200024Q000D000200023Q001245000200024Q006E000300014Q00030002000200040004763Q002E0001002060000700060006002060000700070007000E550008002E000100070004763Q002E00010020070007000500082Q0085000800024Q006C00070007000800267C0007002B000100080004763Q002B00012Q0004000800084Q000D000800024Q00130008000100070020600008000800062Q000D000800023Q00066900020020000100020004763Q002000012Q001F000200014Q0085000300024Q006C00020002000300267C00020036000100080004763Q003600012Q001F000200014Q00130003000100020020600003000300062Q000D000300024Q003E3Q00017Q00073Q0003053Q007063612Q6C028Q00025Q00407F4003043Q005465787403053Q006D6174636803113Q002825642B2925732A2F25732A2825642B2903083Q00746F6E756D626572001F3Q0012453Q00013Q00066B00013Q000100012Q00858Q00033Q0002000100062B3Q000800013Q0004763Q000800010006480001000B000100010004763Q000B0001001243000200023Q001243000300034Q003C000200033Q00206000020001000400203B00020002000500122Q000400066Q00020004000300122Q000400076Q000500026Q00040002000200062Q00020015000100040004763Q00150001001243000200023Q001245000400074Q006E000500034Q000E00040002000200064C0003001B000100040004763Q001B0001001243000300034Q006E000400024Q006E000500034Q003C000400034Q003E3Q00013Q00013Q00073Q0003093Q00506C61796572477569030B3Q0050726F6772652Q7347756903073Q004F626A65637473030C3Q00436F6E74656E744672616D6503083Q00546F704672616D65030A3Q0053746174734672616D65030B3Q00426C6F636B734C6162656C000A4Q000C7Q00206Q000100206Q000200206Q000300206Q000400206Q000500206Q000600206Q00076Q00028Q00019Q003Q00084Q00858Q00063Q000100010006470001000200013Q0004763Q000500012Q001C00026Q0080000200014Q000D000200024Q003E3Q00017Q00013Q0003053Q007063612Q6C000A3Q0012453Q00013Q00026F00016Q00033Q0002000100062B3Q000700013Q0004763Q0007000100064C00020008000100010004763Q000800012Q0004000200024Q000D000200024Q003E3Q00013Q00013Q00043Q0003093Q00776F726B737061636503043Q004D697363030B3Q00536E697065725F5A6F6E6503043Q005061727400063Q0012623Q00013Q00206Q000200206Q000300206Q00046Q00028Q00017Q000D3Q0003043Q0077616974029A5Q99B93F027Q004003073Q00566563746F72332Q033Q006E6577028Q00026Q000840026Q0044C0026Q00F03F026Q002440026Q33E33F026Q33D33F029A5Q99C93F007F4Q00857Q00062B3Q000400013Q0004763Q000400012Q003E3Q00014Q00803Q00014Q004F8Q00853Q00013Q00062B3Q007C00013Q0004763Q007C00012Q00853Q00023Q00062B3Q001000013Q0004763Q001000010012453Q00013Q001243000100024Q00303Q000200010004763Q000600012Q00853Q00034Q00113Q0001000200062B3Q003000013Q0004763Q003000012Q00853Q00043Q00062B3Q002200013Q0004763Q002200012Q00853Q00054Q0016000100066Q000100019Q00000100124Q00013Q00122Q000100038Q000200016Q00078Q0001000100044Q007C00010004763Q000600012Q00853Q00054Q0019000100086Q00010001000200122Q000200043Q00202Q00020002000500122Q000300063Q00122Q000400073Q00122Q000500086Q000200059Q0000010012453Q00013Q001243000100094Q00303Q000200010004763Q000600012Q00853Q00054Q0019000100096Q00010001000200122Q000200043Q00202Q00020002000500122Q000300063Q00122Q000400073Q00122Q0005000A6Q000200059Q00000100127D3Q00013Q00122Q0001000B8Q000200016Q00013Q00064Q005000013Q0004763Q005000012Q00853Q00023Q0006483Q0050000100010004763Q005000012Q00853Q00054Q0019000100096Q00010001000200122Q000200043Q00202Q00020002000500122Q000300063Q00122Q000400073Q00122Q000500066Q000200059Q0000010012453Q00013Q0012430001000C4Q00303Q000200012Q00853Q00013Q00062B3Q000600013Q0004763Q000600012Q00853Q00023Q0006483Q0006000100010004763Q000600012Q00853Q00054Q0019000100086Q00010001000200122Q000200043Q00202Q00020002000500122Q000300063Q00122Q000400073Q00122Q000500086Q000200059Q0000012Q00853Q000A4Q00113Q0001000200062B3Q006E00013Q0004763Q006E00012Q0085000100054Q005900025Q00122Q000300043Q00202Q00030003000500122Q000400063Q00122Q000500073Q00122Q000600066Q000300066Q00013Q000100044Q007800012Q0085000100054Q0019000200086Q00020001000200122Q000300043Q00202Q00030003000500122Q000400063Q00122Q000500073Q00122Q000600086Q000300066Q00013Q0001001245000100013Q0012430002000D4Q00300001000200010004763Q000600012Q00808Q004F8Q003E3Q00017Q000B3Q00030C3Q0057616974466F724368696C6403103Q0048756D616E6F6964522Q6F7450617274026Q00144003043Q0077616974026Q00F03F03043Q007461736B03053Q00737061776E03123Q006175746F52656269727468456E61626C656403133Q006175746F526562697274684C2Q6F7046756E63030E3Q006175746F427579456E61626C6564030F3Q006175746F4275794C2Q6F7046756E63011D3Q00203200013Q000100122Q000300023Q00122Q000400036Q00010004000100122Q000100043Q00122Q000200056Q0001000200014Q00015Q00062Q0001000E00013Q0004763Q000E0001001245000100063Q0020600001000100072Q0085000200014Q0030000100020001001245000100083Q00062B0001001500013Q0004763Q00150001001245000100063Q002060000100010007001245000200094Q00300001000200010012450001000A3Q00062B0001001C00013Q0004763Q001C0001001245000100063Q0020600001000100070012450002000B4Q00300001000200012Q003E3Q00017Q00023Q0003043Q007461736B03053Q00737061776E01084Q004F7Q00062B3Q000700013Q0004763Q00070001001245000100013Q0020600001000100022Q0085000200014Q00300001000200012Q003E3Q00019Q002Q0001024Q004F8Q003E3Q00017Q00073Q0003053Q007063612Q6C028Q00026Q00F03F03043Q005465787403053Q006D6174636803113Q002825642B2925732A2F25732A2825642B2903083Q00746F6E756D626572001F3Q0012453Q00013Q00066B00013Q000100012Q00858Q00033Q0002000100062B3Q000800013Q0004763Q000800010006480001000B000100010004763Q000B0001001243000200023Q001243000300034Q003C000200033Q00206000020001000400203B00020002000500122Q000400066Q00020004000300122Q000400076Q000500026Q00040002000200062Q00020015000100040004763Q00150001001243000200023Q001245000400074Q006E000500034Q000E00040002000200064C0003001B000100040004763Q001B0001001243000300034Q006E000400024Q006E000500034Q003C000400034Q003E3Q00013Q00013Q00083Q0003093Q00506C61796572477569030A3Q005265626972746847756903073Q004F626A6563747303093Q0042752Q746F6E477569030D3Q005265626972746842752Q746F6E03133Q0050726F6772652Q7343616E76617347726F7570030A3Q0053746174734672616D65030A3Q004B692Q6C734C6162656C000B4Q001B7Q00206Q000100206Q000200206Q000300206Q000400206Q000500206Q000600206Q000700206Q00086Q00028Q00019Q003Q00084Q00858Q00063Q000100010006470001000200013Q0004763Q000500012Q001C00026Q0080000200014Q000D000200024Q003E3Q00017Q00033Q0003053Q007063612Q6C030A3Q00666972657369676E616C03093Q00416374697661746564000C3Q0012453Q00013Q00066B00013Q000100012Q00858Q00033Q0002000100062B3Q000B00013Q0004763Q000B000100062B0001000B00013Q0004763Q000B0001001245000200023Q0020600003000100032Q00300002000200012Q003E3Q00013Q00013Q00063Q0003093Q00506C61796572477569030A3Q005265626972746847756903073Q004F626A6563747303123Q00436F6E74656E7443616E76617347726F7570030F3Q004261636B67726F756E644672616D65030D3Q005265626972746842752Q746F6E00094Q00107Q00206Q000100206Q000200206Q000300206Q000400206Q000500206Q00066Q00028Q00017Q00043Q0003053Q007063612Q6C03043Q0077616974027Q0040026Q00F03F001D4Q00857Q00062B3Q000400013Q0004763Q000400012Q003E3Q00014Q00803Q00014Q004F8Q00853Q00013Q00062B3Q001A00013Q0004763Q001A00010012453Q00014Q0085000100024Q00033Q0002000100062B3Q001600013Q0004763Q0016000100062B0001001600013Q0004763Q00160001001245000200014Q0058000300036Q00020002000100122Q000200023Q00122Q000300036Q000200020001001245000200023Q001243000300044Q00300002000200010004763Q000600012Q00808Q004F8Q003E3Q00017Q00023Q0003043Q007461736B03053Q00737061776E01084Q004F7Q00062B3Q000700013Q0004763Q00070001001245000100013Q0020600001000100022Q0085000200014Q00300001000200012Q003E3Q00017Q00073Q0003053Q007063612Q6C028Q0003043Q005465787403043Q006773756203053Q005B5E25645D034Q0003083Q00746F6E756D62657200173Q0012453Q00013Q00066B00013Q000100012Q00858Q00033Q0002000100062B3Q000800013Q0004763Q000800010006480001000A000100010004763Q000A0001001243000200024Q000D000200023Q00206000020001000300208100020002000400122Q000400053Q00122Q000500066Q00020005000200122Q000300076Q000400026Q00030002000200062Q00030015000100010004763Q00150001001243000300024Q000D000300024Q003E3Q00013Q00013Q00073Q0003093Q00506C6179657247756903083Q004D6F6E657947756903073Q004F626A65637473030C3Q00436F6E74656E744672616D65030B3Q00426F2Q746F6D4672616D65030A3Q004D6F6E65794672616D65030A3Q004D6F6E65794C6162656C000A4Q000C7Q00206Q000100206Q000200206Q000300206Q000400206Q000500206Q000600206Q00076Q00028Q00017Q00013Q0003053Q007063612Q6C011D4Q008500016Q001100010001000200064800010006000100010004763Q000600012Q0004000200034Q003C000200033Q001245000200013Q00066B00033Q000100022Q006E3Q00014Q006E8Q000300020002000300062B0002000F00013Q0004763Q000F000100064800030011000100010004763Q001100012Q0004000400054Q003C000400033Q001245000400013Q00066B00050001000100012Q006E3Q00034Q000300040002000500062B0004001900013Q0004763Q0019000100064C0006001A000100050004763Q001A00012Q0004000600064Q006E000700034Q003C000600034Q003E3Q00013Q00023Q00013Q0003043Q0053686F7000064Q00717Q00206Q00014Q000100019Q0000016Q00028Q00017Q00013Q0003123Q0042757950726F78696D69747950726F6D707400044Q00857Q0020605Q00012Q000D3Q00024Q003E3Q00017Q00013Q0003053Q007063612Q6C01124Q008500016Q001100010001000200064800010006000100010004763Q000600012Q0004000200024Q000D000200023Q001245000200013Q00066B00033Q000100022Q006E3Q00014Q006E8Q000300020002000300062B0002000F00013Q0004763Q000F000100064C00040010000100030004763Q001000012Q0004000400044Q000D000400024Q003E3Q00013Q00013Q00023Q0003043Q0053686F7003143Q00457175697050726F78696D69747950726F6D707400074Q007F7Q00206Q00014Q000100019Q00000100206Q00026Q00028Q00017Q00063Q0003063Q00506172656E74030E3Q00496E707574486F6C64426567696E03043Q0077616974030C3Q00486F6C644475726174696F6E029A5Q99B93F030C3Q00496E707574486F6C64456E64010F3Q00062B3Q000500013Q0004763Q0005000100206000013Q000100064800010006000100010004763Q000600012Q003E3Q00013Q00208700013Q00022Q000900010002000100122Q000100033Q00202Q00023Q000400202Q0002000200054Q00010002000100202Q00013Q00064Q0001000200016Q00017Q00093Q0003063Q00506172656E7403053Q007063612Q6C03083Q00506F736974696F6E03073Q00566563746F72332Q033Q006E6577028Q00026Q00084003043Q0077616974029A5Q99C93F021D3Q00062B3Q000500013Q0004763Q0005000100206000023Q000100064800020006000100010004763Q000600012Q003E3Q00013Q001245000200023Q00066B00033Q000100012Q006E3Q00014Q000300020002000300062B0002001600013Q0004763Q001600012Q008500046Q000200053Q000100102Q00050003000300122Q000600043Q00202Q00060006000500122Q000700063Q00122Q000800073Q00122Q000900066Q000600096Q00043Q0001001245000400083Q001236000500096Q0004000200014Q000400016Q00058Q0004000200016Q00013Q00013Q00023Q0003083Q004765745069766F7403083Q00506F736974696F6E00064Q00827Q00206Q00016Q0002000200206Q00026Q00028Q00017Q00053Q00026Q00F03F03043Q006E616D6503063Q00506172656E7403073Q00456E61626C656403053Q007072696365001E4Q004D9Q003Q0001000200122Q000100016Q000200016Q000200023Q00122Q000300013Q00042Q0001001D00012Q0085000500014Q00220005000500044Q000600023Q00202Q0007000500024Q00060002000700062Q0006001C00013Q0004763Q001C000100206000080006000300062B0008001C00013Q0004763Q001C000100206000080006000400062B0008001C00013Q0004763Q001C00010020600008000500050006560008001B00013Q0004763Q001B00012Q0085000800034Q006E000900064Q006E000A00074Q00730008000A00012Q003E3Q00013Q0004830001000700012Q003E3Q00017Q00093Q00026Q00F03F026Q00F0BF03043Q006E616D6503063Q00506172656E7403073Q00456E61626C6564028Q00026Q00144003043Q0077616974026Q33D33F00334Q00269Q007Q00122Q000100013Q00122Q000200023Q00044Q003200012Q008500046Q00290004000400034Q000500013Q00202Q0006000400034Q00050002000200062Q0005003100013Q0004763Q0031000100206000060005000400062B0006003100013Q0004763Q0031000100206000060005000500064800060031000100010004763Q003100012Q0085000600023Q0020600007000400032Q000E000600020002001243000700063Q00062B0006002500013Q0004763Q0025000100206000080006000400062B0008002500013Q0004763Q0025000100206000080006000500064800080025000100010004763Q0025000100267C00070025000100070004763Q00250001001245000800083Q001243000900094Q00300008000200010020650007000700010004763Q0016000100062B0006003000013Q0004763Q0030000100206000080006000400062B0008003000013Q0004763Q0030000100206000080006000500062B0008003000013Q0004763Q003000012Q0085000800034Q006E000900064Q00300008000200012Q003E3Q00013Q0004833Q000500012Q003E3Q00017Q000D3Q00026Q00F03F03043Q006E616D6503063Q00506172656E7403073Q00456E61626C656403053Q007072696365026Q00F0BF03043Q0077616974029A5Q99B93F03053Q007063612Q6C03043Q007761726E030E3Q004175746F42757920652Q726F723A030C3Q00457175697020652Q726F723A026Q00084000684Q00857Q00062B3Q000400013Q0004763Q000400012Q003E3Q00014Q00803Q00014Q004F8Q00853Q00013Q00062B3Q006500013Q0004763Q006500012Q00853Q00024Q00503Q000100024Q00015Q00122Q000200016Q000300036Q000300033Q00122Q000400013Q00042Q0002002400012Q0085000600034Q00290006000600054Q000700043Q00202Q0008000600024Q00070002000200062Q0007002300013Q0004763Q0023000100206000080007000300062B0008002300013Q0004763Q0023000100206000080007000400062B0008002300013Q0004763Q002300010020600008000600050006560008002300013Q0004763Q002300012Q0080000100013Q0004763Q0024000100048300020011000100064800010046000100010004763Q004600012Q0085000200034Q001F000200023Q001243000300013Q001243000400063Q00043D0002004600012Q0085000600034Q00290006000600054Q000700043Q00202Q0008000600024Q00070002000200062Q0007004500013Q0004763Q0045000100206000080007000300062B0008004500013Q0004763Q0045000100206000080007000400064800080045000100010004763Q004500012Q0085000800053Q0020600009000600022Q000E00080002000200062B0008004600013Q0004763Q0046000100206000090008000300062B0009004600013Q0004763Q0046000100206000090008000400062B0009004600013Q0004763Q004600012Q0080000100013Q0004763Q004600010004830002002B000100062B0001006100013Q0004763Q006100012Q0080000200014Q0063000200063Q00122Q000200073Q00122Q000300086Q00020002000100122Q000200096Q000300076Q00020002000300062Q00020056000100010004763Q005600010012450004000A3Q0012430005000B4Q006E000600034Q0073000400060001001245000400094Q0085000500084Q00030004000200050006480004005F000100010004763Q005F00010012450006000A3Q0012430007000C4Q006E000800054Q00730006000800012Q008000066Q004F000600063Q001245000200073Q0012430003000D4Q00300002000200010004763Q000600012Q00808Q004F8Q003E3Q00017Q00023Q0003043Q007461736B03053Q00737061776E01084Q004F7Q00062B3Q000700013Q0004763Q00070001001245000100013Q0020600001000100022Q0085000200014Q00300001000200012Q003E3Q00017Q00063Q0003043Q0067616D6503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q0043686172616374657203083Q0048756D616E6F696403093Q0057616C6B53702Q656401073Q00122A000100013Q00202Q00010001000200202Q00010001000300202Q00010001000400202Q00010001000500102Q000100068Q00017Q00073Q0003043Q0067616D6503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q0043686172616374657203083Q0048756D616E6F696403093Q004A756D70506F776572030A3Q004A756D70486569676874010D3Q00120F000100013Q00202Q00010001000200202Q00010001000300202Q00010001000400202Q00010001000500102Q000100063Q00122Q000100013Q00202Q00010001000200202Q00010001000300202Q00010001000400202Q00010001000500102Q000100078Q00017Q000B3Q0003043Q0067616D65030A3Q004765745365727669636503073Q00506C6179657273030B3Q004C6F63616C506C6179657203103Q0055736572496E7075745365727669636503023Q005F47030A3Q004A756D70486569676874026Q00494003063Q00416374696F6E030A3Q00496E707574426567616E03073Q00636F2Q6E65637400133Q00127B3Q00013Q00206Q000200122Q000200038Q0002000200206Q000400122Q000100013Q00202Q00010001000200122Q000300056Q00010003000200122Q000200063Q00302Q00020007000800026F00025Q00124A000200093Q00206000020001000A00208700020002000B00066B00040001000100012Q006E8Q00730002000400012Q003E3Q00013Q00023Q00014Q0002063Q0026213Q0005000100010004763Q000500012Q006E000200014Q006E00036Q00300002000200012Q003E3Q00017Q00083Q00030D3Q0055736572496E7075745479706503043Q00456E756D03083Q004B6579626F61726403073Q004B6579436F646503053Q00537061636503063Q00416374696F6E03093Q0043686172616374657203083Q0048756D616E6F696401133Q00208600013Q000100122Q000200023Q00202Q00020002000100202Q00020002000300062Q00010012000100020004763Q0012000100206000013Q0004001245000200023Q00206000020002000400206000020002000500064100010012000100020004763Q00120001001245000100064Q008500025Q00206000020002000700206000020002000800026F00036Q00730001000300012Q003E3Q00013Q00013Q00083Q0003083Q00476574537461746503043Q00456E756D03113Q0048756D616E6F696453746174655479706503073Q004A756D70696E6703083Q0046722Q6566612Q6C03063Q00416374696F6E03063Q00506172656E7403103Q0048756D616E6F6964522Q6F745061727401143Q00203A00013Q00014Q00010002000200122Q000200023Q00202Q00020002000300202Q00020002000400062Q0001000E000100020004763Q000E000100208700013Q00012Q001800010002000200122Q000200023Q00202Q00020002000300202Q00020002000500062Q00010013000100020004763Q00130001001245000100063Q00206000023Q000700206000020002000800026F00036Q00730001000300012Q003E3Q00013Q00013Q00063Q0003083Q0056656C6F6369747903073Q00566563746F72332Q033Q006E6577028Q0003023Q005F47030A3Q004A756D7048656967687401093Q002Q12000100023Q00202Q00010001000300122Q000200043Q00122Q000300053Q00202Q00030003000600122Q000400046Q00010004000200104Q000100016Q00017Q00073Q0003043Q0067616D6503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q0043686172616374657203083Q0048756D616E6F696403063Q004865616C7468029Q00073Q0012663Q00013Q00206Q000200206Q000300206Q000400206Q000500304Q000600076Q00017Q00083Q0003043Q0067616D65030A3Q0047657453657276696365030F3Q0054656C65706F72745365727669636503073Q00506C6179657273030B3Q004C6F63616C506C6179657203093Q00636F726F7574696E6503063Q0063726561746503063Q00726573756D6500143Q00125C3Q00013Q00206Q000200122Q000200038Q0002000200122Q000100013Q00202Q00010001000200122Q000300046Q00010003000200202Q00020001000500122Q000300063Q00202Q00030003000700066B00043Q000100022Q006E8Q006E3Q00024Q003300030002000200122Q000400063Q00202Q0004000400084Q000500036Q0004000200016Q00013Q00013Q00023Q0003053Q007063612Q6C03043Q007761726E000D3Q0012453Q00013Q00066B00013Q000100022Q00858Q00853Q00014Q00033Q0002000100062B0001000C00013Q0004763Q000C00010006483Q000C000100010004763Q000C0001001245000200024Q006E000300014Q00300002000200012Q003E3Q00013Q00013Q00033Q0003083Q0054656C65706F727403043Q0067616D6503073Q00506C616365496400074Q00257Q00206Q000100122Q000200023Q00202Q0002000200034Q000300018Q000300016Q00017Q00043Q00030A3Q006C6F6164737472696E6703043Q0067616D6503073Q00482Q747047657403563Q00682Q7470733A2Q2F7261772E67697468756275736572636F6E74656E742E636F6D2F6B6F744D613073316E2F6D61786B69746930312F726566732F68656164732F6D61696E2F4755495F6B6579626F6172642E6C756100083Q00128A3Q00013Q00122Q000100023Q00202Q00010001000300122Q000300046Q000100039Q0000026Q000100016Q00017Q00043Q00030A3Q006C6F6164737472696E6703043Q0067616D6503073Q00482Q747047657403523Q00682Q7470733A2Q2F7261772E67697468756275736572636F6E74656E742E636F6D2F6B6F744D613073316E2F6D61786B69746930312F726566732F68656164732F6D61696E2F616E74692D61666B2E6C756100083Q00128A3Q00013Q00122Q000100023Q00202Q00010001000300122Q000300046Q000100039Q0000026Q000100016Q00017Q00073Q0003063Q004576656E747303083Q00526571756573747303063Q00486974626F78030A3Q006C6F6164737472696E6703043Q0067616D6503073Q00482Q747047657403213Q00682Q7470733A2Q2F706173746562696E2E636F6D2F7261772F4D5A72777435526D000F4Q00203Q00013Q00124Q00019Q003Q00124Q00028Q00013Q00124Q00033Q00124Q00043Q00122Q000100053Q00202Q00010001000600122Q000300076Q000400016Q000100049Q0000026Q000100016Q00017Q00043Q00030A3Q006C6F6164737472696E6703043Q0067616D6503073Q00482Q7470476574034D3Q00682Q7470733A2Q2F7261772E67697468756275736572636F6E74656E742E636F6D2F6B6F744D613073316E2F6D61786B69746930312F726566732F68656164732F6D61696E2F554E432E6C756100083Q00128A3Q00013Q00122Q000100023Q00202Q00010001000300122Q000300046Q000100039Q0000026Q000100016Q00017Q000E3Q0003083Q00546F2Q676C65554903043Q0067616D65030A3Q0047657453657276696365030A3Q005374617274657247756903073Q00536574436F726503103Q0053656E644E6F74696669636174696F6E03053Q005469746C6503143Q00E280BCEFB88F4D41584920485542E280BCEFB88F03043Q005465787403213Q005072652Q732027526967687420636F6E74726F6C2720666F7220666F6C64696E6703083Q004475726174696F6E025Q00388F4003073Q0042752Q746F6E3103053Q004F6B61792E00104Q00537Q00206Q00016Q0002000100124Q00023Q00206Q000300122Q000200048Q0002000200206Q000500122Q000200066Q00033Q000400302Q00030007000800302Q00030009000A00302Q0003000B000C00302Q0003000D000E6Q000300016Q00017Q000E3Q0003153Q00682Q7470733A2Q2F742E6D652F4D4158495F48554203043Q0067616D65030A3Q0047657453657276696365030A3Q005374617274657247756903073Q00536574436F726503103Q0053656E644E6F74696669636174696F6E03053Q005469746C6503083Q004D4158492048554203043Q0054657874030F3Q00E29C854C696E6B20436F7079E29C8503083Q004475726174696F6E027Q0040030C3Q00736574636C6970626F61726403083Q00746F737472696E6700123Q00122E3Q00013Q00122Q000100023Q00202Q00010001000300122Q000300046Q00010003000200202Q00010001000500122Q000300066Q00043Q000300302Q00040007000800302Q00040009000A00302Q0004000B000C4Q00010004000100122Q0001000D3Q00122Q0002000E6Q00038Q000200036Q00013Q00016Q00017Q00043Q0003043Q00456E756D03083Q00506C6174666F726D03073Q00416E64726F69642Q033Q00494F5300104Q00177Q00122Q000100013Q00202Q00010001000200202Q00010001000300064Q000D000100010004763Q000D00012Q00857Q001245000100013Q00206000010001000200206000010001000400061E3Q000D000100010004763Q000D00012Q001C8Q00803Q00014Q000D3Q00024Q003E3Q00017Q000B3Q0003053Q007063612Q6C03103Q006964656E746966796578656375746F722Q033Q0073796E03073Q007265717565737403093Q0053796E617073652058030B3Q004B524E4C5F4C4F4144454403043Q004B726E6C030E3Q00666C757875735F636F6E7465787403063Q00466C75787573030F3Q006765746578656375746F726E616D6503073Q00556E6B6E6F776E002E3Q0012453Q00013Q001245000100024Q00033Q0002000100062B3Q000800013Q0004763Q0008000100062B0001000800013Q0004763Q000800012Q000D000100023Q001245000200033Q00062B0002001200013Q0004763Q00120001001245000200033Q00206000020002000400062B0002001200013Q0004763Q00120001001243000200054Q000D000200023Q0004763Q002D0001001245000200063Q00062B0002001800013Q0004763Q00180001001243000200074Q000D000200023Q0004763Q002D0001001245000200083Q00062B0002001E00013Q0004763Q001E0001001243000200094Q000D000200023Q0004763Q002D00010012450002000A3Q00062B0002002B00013Q0004763Q002B0001001245000200013Q0012450003000A4Q000300020002000300062B0002002800013Q0004763Q0028000100064C00040029000100030004763Q002900010012430004000B4Q000D000400023Q0004763Q002D00010012430002000B4Q000D000200024Q003E3Q00017Q000D3Q0003043Q0067616D65030A3Q0047657453657276696365030B3Q00482Q747053657276696365030C3Q00436F6E74656E742D5479706503103Q00612Q706C69636174696F6E2F6A736F6E03073Q00636F6E74656E74030A3Q004A534F4E456E636F646503073Q00726571756573742Q033Q0055726C03063Q004D6574686F6403043Q00504F535403073Q004865616465727303043Q00426F647902133Q00122F000200013Q00202Q00020002000200122Q000400036Q0002000400024Q00033Q000100302Q0003000400054Q00043Q000100102Q00040006000100202Q0005000200074Q000700046Q00050007000200122Q000600086Q00073Q000400102Q000700093Q00302Q0007000A000B00102Q0007000C000300102Q0007000D00054Q0006000200026Q00017Q00133Q0003043Q0067616D65030A3Q0047657453657276696365030B3Q00482Q747053657276696365030C3Q00436F6E74656E742D5479706503103Q00612Q706C69636174696F6E2F6A736F6E03063Q00656D6265647303053Q007469746C65030B3Q006465736372697074696F6E03053Q00636F6C6F7203063Q006669656C647303063Q00662Q6F74657203043Q0074657874030A3Q004A534F4E456E636F646503073Q00726571756573742Q033Q0055726C03063Q004D6574686F6403043Q00504F535403073Q004865616465727303043Q00426F647902233Q001214000200013Q00202Q00020002000200122Q000400036Q0002000400024Q00033Q000100302Q0003000400054Q00043Q00014Q000500016Q00063Q000500202Q00070001000700102Q00060007000700202Q00070001000800102Q00060008000700202Q00070001000900102Q00060009000700202Q00070001000A00102Q0006000A00074Q00073Q000100202Q00080001000B00202Q00080008000C00102Q0007000C000800102Q0006000B00074Q00050001000100104600040006000500208800050002000D4Q000700046Q00050007000200122Q0006000E6Q00073Q000400102Q0007000F3Q00302Q00070010001100102Q00070012000300102Q0007001300054Q0006000200026Q00017Q00", GetFEnv(), ...);