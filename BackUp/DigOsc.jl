#!/usr/local/bin/julia

module DigOsc
using FixedPointNumbers
using BenchmarkTools
using Debugger
using YAML
import Base: promote_rule, convert
export Rg, Wr, GetRg, GetWr, SetRg, SetVl, GetVl
export Sgmt, Bus, addSgmt

abstract type FxdPnt <: Integer end

mutable struct Rg
  sz::UInt8
  sgn::UInt8
  val::Int64
end

mutable struct Wr
  sz::UInt8
  sgn::UInt8
  val::Int64
end

mutable struct Sgmt
  strt::UInt8
  nmbBits::UInt8
  srcTyp:UInt8
  src::Int16
  val::Int64
  Sgmt() = new()
end

mutable struct Bus
  name::String
  nmbBits::UInt8
  nmbSgs::UInt8
  srcTyp::UInt8
  sgnFlg::UInt8
  tmFlg::UInt8
  tmIndx::UInt16
  src::Int16
  val::Int64
  sgmts::Vector{Sgmt}
  lstChng::Int64
  Bus() = new()
end

mutable struct ACirc
  name::String
  typ::UInt8
  delay::UInt16
  inPrts::Vector{Bus}
  outPrts::Vector{Bus}
end

mutable struct RCirc
  name::String
  typ::UInt8
  tmFlg::UInt8
  delay:UInt16
  inPrts::Vector{Bus}
  outPrts::Vector{Bs}
  rgs::Vector{Rg}
  aCrcs::Vector{ACirc}
  tmChngs::{TmChng}
end

mutable struct TmChng
  per::Int64
  tm::Int64
end

function addSgmt(bs::Bus, sg::Sgmt)
  push!(bs.sgmts, sg)
end

accm_0 = YAML.load(open("accmCirc.yml"))


# convert(::Type{Bool}, x::Number) = (x!=0)
##
function convert(::Type{Rg}, wr::Wr)
  rg = Rg(wr.sz, wr.sgn, wr.val)
end
function convert(::Type{Wr}, rg::Rg)
  wr = Wr(rg.sz, rg.sgn, rg.val)
end
##

GlbSz = 16
GlbSgn = 1
nullBus = Wr(0, 0, 0)

function GetRg(val::Integer)::Rg
  global GlbSz, GlbSgn
  rg = Rg(GlbSz,GlbSgn,val)
  return rg
end

function GetWr(val::Integer)::Wr
  global GlbSz, GlbSz
  wr = Wr(GlbSz,GlbSgn,val)
  return wr
end

function Wr2Rg(wr::Wr)::Rg
  rtrnRg = Rg(wr.sz, wr.sgn, wr.val)
end

Sgnl = Union{Rg, Wr}

FxdSgnl = Union{Vector{Rg},Vector{Wr}}

function GetVl(sg::Sgnl)::Int64
  vl = sg.val
  sz = sg.sz
  sgn = sg.sgn
  if sgn == 1
    rtrn=vl
  else
    chkNeg = (1<<(sz-1)&vl)
    if chkNeg != 0
      vl = vl - (1<<sz)
    end
  end
  return vl
end

function SetVl(sg::Sgnl, val::Int)::Sgnl
  sg.val = int2cmpl(val, sg.sz)
  return vl
end

# promote_rule(::Type{Wr}, ::Type{Rg}) = Rg
wr1 = Wr(8, 0, 17)
rg1 = Wr2Rg(wr1)
typ = typeof(rg1)

getRow(a,i) = reshape(a[:,i],1,:)

function readRom0()
  lns = readlines("rom0.dat");
  lns2 = parse.(UInt16, lns);
  return lns2
end
rom0Dat = readRom0();

function rom0Mem(addr::Union{Wr,Rg})::Rg
  global rom0Dat
  addr_ = addr.val + 1
  data = rom0Dat[addr_]
  datRg = GetRg(data)
  return datRg
end

function readRom1()
  lns = readlines("rom1.dat");
  lns2 = parse.(UInt16, lns);
  return lns2
end
rom1Dat = readRom1();

function rom1Mem(addr::Union{Wr,Rg})::Rg
  global rom1Dat
  addr_ = addr.val + 1
  data = rom1Dat[addr_]
  datRg = GetRg(data)
  return datRg
end

rdRom1(addr) = rom1Mem(GetWr(addr))

rdRom0(addr) = rom0Mem(GetWr(addr))


function add2cmpl(a::Int, b::Int)
  ((a & 0xFFFF) + (b & 0xFFFF)) & 0xFFFF
end

function sub2cmpl(a::Int, b::Int)
  ((a & 0xFFFF) + ((1<<16) - (b & 0xFFFF))) & 0xFFFF
end

function mult2cmpl(a::Int, b::Int)
  if (a&0x8000)
    x1 = a - (1<<16)
  else
    x1 = a&0x7FFF
  end
  if (b&0x8000)
    x2 = b - (1<<16)
  else
    x2 = b&0x7FFF
  end
  x3 = x1*x2
  x4 = int(x3 / (1<<16))
  if (x4 < 0)
    x5 = (1<<16) + x4
  else
    x5 = x4
  end
  return x5
end

function twos_rg1COmp(val::Int, bits::Int)
  if ((val & (1 << (bits - 1))) != 0)
    val = val - (1 << bits)
  end
  return val
end

function cmpl2int(x::Int, n::Int)
  (x&((1<<(n-1))-1)) - (x&(1<<(n-1)))
end

function int2cmpl(x::Int, n::Int)
  x&((1<<n)-1)
end

function cmplInvrt(x::Int, n::Int)
  int2cmpl(-cmpl2int(x, n), n)
end

function cmplInvrt(x::Int, n::Int)
  (~x)&((1<<n)-1)
end

function cmplMult(a, b, n)
  ((cmpl2int(a,n) * cmpl2int(b,n)))>>(n)
end

function cmplAdd(a, b, n)
  (cmpl2int(a,n) + cmpl2int(b,n))&((1<<n)-1)
end

function cmplSubt(a, b, n)
  (cmpl2int(a,n) - cmpl2int(b,n))&((1<<n)-1)
end

function plr2Rct(M::Float64, phi::Float64) ::Complex
  M*complex(cos(phi), sin(phi));
end

function initOsc(k::Float64, N::Int)
  osc = Osc()
  osc.N = N
  osc.k = trunc(Int, (2*sin(pi*k))*(1<<16)+0.5)
  msk1 = (1 << (N - 1))
  osc.msk1 = msk1
  osc.msk0 = (msk1 - 1)
  osc.msk2 = ((1<<N) - 1)
  osc.msk3 = (1<<(N*2) - 1)
  xpk = 7 << (N - 4)
  osc.xpk = xpk
  n = -1;
  phi = 2*pi*n/osc.N;
  xs = plr2Rct(Float64(osc.xpk), phi);
  xsReal = trunc(Int, real(xs));
  
  osc.xi1 = int2cmpl(xsReal, N);
  osc.xi2 = osc.xi1;
  osc.x2o = 0;
  osc.x1o = xpk;
  return osc
end

function updOsc(osc)
  m1 = cmplMult(osc.x2o, osc.k, osc.N)
  osc.xi1 = sub2cmpl(osc.x1o , m1)
  m2 = cmplMult(osc.xi1, osc.k, osc.N)
  osc.xi2 = add2cmpl(osc.x2o, m2)
  osc.x1o = osc.xi1
  osc.x2o = osc.xi2
  return (cmpl2int(osc.x1o, osc.N), cmpl2int(osc.x2o, osc.N))
end

accum0 = GetRg(0)
accum1 = GetRg(0)

function updAccum0!(rg::Rg, delt::Sgnl)::Rg
  dlt = delt.val
  accm0 = rg.val
  sum = cmplAdd(accm0, dlt, 16)
  rg.val = sum
  return rg
end

function updAccum1!(rg::Rg, delt::Sgnl)
  dlt = delt.val
  accm1 = rg.val
  rg1CO = dlt+accm1 >= 0x10 ? 1 : 0;
  sum = cmplAdd(accm1, dlt, 4)
  rg.val = sum
  return (rg, rg1CO)
end

function oneCmpl(cntrl::Wr, datIn::Wr)::Wr
  @assert (cntrl.sz == 1) "The control of a oneCmpl block must be a single bit"
  datI = datIn.val
  sz = convert(Int,datIn.sz)
  datO = (cntrl.val == 1) ? cmplInvrt(datI, sz) : datI
  datOut = Wr(sz, 0, datO)
  return datOut
end

function slctBts(dat::Sgnl, n1, n2; unsgnd=0)::Wr
  msk = (1<<(n1 - n2 + 1))-1
  sz = n1 - n2 + 1
  bts = (dat.val >> n2)&msk
  rtrnWr = Wr(sz, unsgnd, bts)
  return rtrnWr
end

function joinBts(wr1::Sgnl, wr2::Sgnl; unsgnd=0)::Wr
  vl1 = wr1.val << wr2.sz
  vl = vl1 | wr2.val
  sz = wr1.sz + wr2.sz
  rtrn = Wr(sz, unsgnd, vl)
end

function addSgnl(a::Sgnl, b::Sgnl)::Wr
  val1 = a.val
  val2 = b.val
  sz0 = (a.sz >= b.sz) ? a.sz : b.sz
  sgn = a.sgn & b.sgn
  sz = convert(Int64,sz0)
  out = cmplAdd(val1, val2, sz)
  rtrWr = Wr(sz0, sgn, out)
end

function subtSgnl(a::Sgnl, b::Sgnl)::Wr
  val1 = a.val
  val2 = b.val
  sz0 = (a.sz >= b.sz) ? a.sz : b.sz
  sgn = a.sgn & b.sgn
  sz = convert(Int64,sz0)
  out = cmplSubt(val1, val2, sz)
  rtrWr = Wr(sz0, sgn, out)
end

function updRg!(a::Rg, b::Wr)::Rg
  a.sz = b.sz
  a.sgn = b.sgn
  a.val = b.val
  return a
end

function cnvrtI2Cmpl(x, N)
  parse(Int, bitstring(0.635Q0f16); base=2)
end

function __init__()
  println("Hello from Ken")
end

mutable struct Osc
  N::Int
  msk0::Int
  msk1::Int
  msk2::Int
  msk3::Int
  xpk::Int
  xi1::Int
  xi2::Int
  x2o::Int
  x1o::Int
  x1i::Int
  x2i::Int
  k::Int
  Osc() = new()
end

#=

=#
function slct_(s::FxdSgnl, x0::FxdSgnl, x1::FxdSgnl)::FxdSgnl
  c = Wr(0x8, 0x1, 0);
  c.sz = x0.sz;
  c.sgn = x0.sgn;
  c.val = s.val == 0 ? x0.val : x1.val
  return c
end

function slct4_(slct::FxdSgnl, x0::Vector{Vector{Main.DigOsc.Rg}})::Wr
  c = Wr(0, 0, 0);
  x01 = x0[1];
  c_ = x01;
  c.sgn=c_[1].sgn
  c.sz=c_[1].sz
  c.val=c_[1].val

  s = slct[1]
  if s.val == 0
    c.val = x0[1].val
  elseif s.val == 1
    c.val = x0[2].val
  elseif s.val == 2
    c.val = x0[1][1].val
  elseif c.val == 3
    c.val = x0[4].val
  end
  return c
end

function and_(a::FxdSgnl, b::FxdSgnl)::FxdSgnl
  c = Wr(0,0,0);
  c.sz = a.sz;
  c.sgn = a.sgn;
  c.val = a.val .& b.val
  return c
end

function or_(a::FxdSgnl, b::FxdSgnl)::FxdSgnl
  c = Wr(0,0
  ,0);
  c.sz = a.sz;
  c.sgn = a.sgn;
  c.val = a.val .| b.val
  return c
end

function nor_(a::FxdSgnl, b::FxdSgnl)::FxdSgnl
  c = Wr(0,0,0);
  c.sz = a.sz;
  c.sgn = a.sgn;
  c.val = .~(a .| b)
  return c
end

function nand_(a::FxdSgnl, b::FxdSgnl)::FxdSgnl
  c = Wr(0,0,0);
  c.sz = a.sz;
  c.sgn = a.sgn;
  c.val = .~(a .& b)
  return c
end

function exor_(a::FxdSgnl,b::FxdSgnl)::FxdSgnl
  c = Wr(0,0,0);
  c.sz = a.sz;
  c.sgn = a.sgn;
  c.val = a .⊻ b
  return c
end

function exnor_(a::FxdSgnl,b::FxdSgnl)::FxdSgnl
  c = Wr(0,0,0);
  c.sz = a.sz;
  c.sgn = a.sgn;
  c.val = .~(a .⊻ b)
  return c
end

function mkBus(a::Sgnl, (n1a, n2a), b::Sgnl, (n1b, n2b))::Wr
  btsa = slctBts(a, n1a, n2a)
  btsb = slctBts(b, n1b, n2b)
  if b.sz== 0
    wrOut = btsa
  else
    wrOut = joinBts(btsa, btsb)
  end
  return wrOut
end

function dtctOvr(a::Sgnl, b::Sgnl)::Wr
  vl1 = a.val
  vl2 = b.val
  ovrFlSz = 1<<(a.sz)
  ovrFl = vl1 + vl2 >= ovrFlSz ? 1 : 0
  rtrnWr = Wr(1,1,ovrFl)
end

dI = Wr(12, 0, 0b11110100)
dO = slctBts(dI, 4, 2)
cnt = Wr(1, 1, 1)
dI = Wr(12, 0, 0b1111)
dO = oneCmpl(cnt, dI)

wrFreq = Wr(20, 0, 0x10000)

rgAccm0Init = 0x4000
rgAccm1Init = 0
rgAccm0rInit = 0x4000
rgAccm1rInit = 0
rgAccm0qInit = 0
rgAccm1qInit = 0
rgRom0Init = 0
rgRom1Init = 0
rgAccmMsbInit = 0
rgOutInit = 0

rgAccm0 = Rg(16,0,rgAccm0Init)
rgAccm1 = Rg(4,0,rgAccm1Init)
rgRom0A = Rg(12,0,rgRom0Init)
rgRom0B = Rg(12,0,rgRom0Init)
rgRom1A = Rg(4,0,rgRom1Init)
rgRom1B = Rg(4,0,rgRom1Init)
rgMsbA = Rg(1,0,rgAccmMsbInit)
rgMsbB = Rg(1,0,rgAccmMsbInit)
rgOut = Rg(12,0,rgOutInit)
rgAccm0r = Rg(16,0,rgAccm0rInit)
rgAccm1r = Rg(4,0,rgAccm1rInit)
rgAccm0q = Rg(16,0,rgAccm0qInit)
rgAccm1q = Rg(4,0,rgAccm1qInit)

rgs = [
rgAccm0,
rgAccm1,
rgRom0A,
rgRom0B,
rgRom1A,
rgRom1B,
rgMsbA,
rgMsbB,
rgOut,
rgAccm0r,
rgAccm1r,
rgAccm0q,
rgAccm1
]

rgsA2Sin = [
rgRom0A,
rgRom0B,
rgRom1A,
rgRom1B,
rgMsbA,
rgMsbB,
rgOut
]

rgsAccmQd = [
rgAccm0r,
rgAccm1r,
rgAccm0q,
rgAccm1q
]

macro rom0a()
  return :( rgsA2Sin[1] )
end

macro rom0b()
  return :( rgsA2Sin[2] )
end

macro rom1a()
  return :( rgsA2Sin[3] )
end

macro rom1b()
  return :( rgsA2Sin[4] )
end

macro msba()
  return :( rgsA2Sin[5] )
end

macro msbb()
  return :( rgsA2Sin[6] )
end

macro out()
  return :( rgsA2Sin[7] )
end

macro accm0r()
  return :( rgsAccmQd[1] )
end

macro accm1r()
  return :( rgsAccmQd[2] )
end

macro accm0q()
  return :( rgsAccmQd[3] )
end

macro accm1q()
  return :( rgsAccmQd[4] )
end

macro setAccm0(val)
  return :( SetVl(rgs[1], $val) )
end

rgRom0Ar = Rg(12,0,rgRom0Init)
rgRom0Br = Rg(12,0,rgRom0Init)
rgRom1Ar = Rg(4,0,rgRom1Init)
rgRom1Br = Rg(4,0,rgRom1Init)
rgMsbAr = Rg(1,0,rgAccmMsbInit)
rgMsbBr = Rg(1,0,rgAccmMsbInit)
rgOutr = Rg(12,0,rgOutInit)

rgRom0Aq = Rg(12,0,rgRom0Init)
rgRom0Bq = Rg(12,0,rgRom0Init)
rgRom1Aq = Rg(4,0,rgRom1Init)
rgRom1Bq = Rg(4,0,rgRom1Init)
rgMsbAq = Rg(1,0,rgAccmMsbInit)
rgMsbBq = Rg(1,0,rgAccmMsbInit)
rgOutq = Rg(12,0,rgOutInit)

rgsA2Sinr = [
rgRom0Ar,
rgRom0Br,
rgRom1Ar,
rgRom1Br,
rgMsbAr,
rgMsbBr,
rgOutr
]

rgsA2Sinq = [
rgRom0Aq,
rgRom0Bq,
rgRom1Aq,
rgRom1Bq,
rgMsbAq,
rgMsbBq,
rgOutq
]

filt = YAML.load(open(flNm))

macro rom0ar()
  return :( rgsA2Sinr[1] )
end

macro rom0br()
  return :( rgsA2Sinr[2] )
end

macro rom1ar()
  return :( rgsA2Sinr[3] )
end

macro rom1br()
  return :( rgsA2Sinr[4] )
end

macro msbar()
  return :( rgsA2Sinr[5] )
end

macro msbbr()
  return :( rgsA2Sinr[6] )
end

macro outr()
  return :( rgsA2Sinr[7] )
end

macro rom0aq()
  return :( rgsA2Sinq[1] )
end

macro rom0bq()
  return :( rgsA2Sinq[2] )
end

macro rom1aq()
  return :( rgsA2Sinq[3] )
end

macro rom1bq()
  return :( rgsA2Sinq[4] )
end

macro msbaq()
  return :( rgsA2Sinq[5] )
end

macro msbbq()
  return :( rgsA2Sinq[6] )
end

macro outq()
  return :( rgsA2Sinr[7] )
end

function updAccum!(freq::Sgnl, rg0::Rg, rg1::Rg)
  accm0Dlt = slctBts(freq, 19, 4)
  accm1Dlt = slctBts(freq, 3, 0)
  rg0 = updAccum0!(rg0, accm0Dlt)
  (rg1, rg1CO) = updAccum1!(rg1, accm1Dlt)
  if rg1CO == 1
    rg0 = addSgnl(rg0, Wr(rg0.sz, rg0.sgn, 1))
  end
  return rg0, rg1
end


function updQdAccum!(freq::Sgnl, rg0r::Rg, rg1r::Rg, rg0q::Rg, rg1q::Rg)
  accm0Dlt = slctBts(freq, 19, 4)
  accm1Dlt = slctBts(freq, 3, 0)
  rg0r = updAccum0!(rg0r, accm0Dlt)
  (rg1r, rg1COr) = updAccum1!(rg1r, accm1Dlt)
  if rg1COr == 1
    rg0r = addSgnl(rg0r, Wr(rg0r.sz, rg0r.sgn, 1))
  end
  rg0q = updAccum0!(rg0q, accm0Dlt)
  (rg1q, rg1COq) = updAccum1!(rg1q, accm1Dlt)
  if rg1COr == 1
    rg0q = addSgnl(rg0q, Wr(rg0q.sz, rg0q.sgn, 1))
  end
  return rg0r, rg1r, rg0q, rg1q
end

function updA2Sin!(rgIn::Sgnl, rgsA2Sin::Array{Rg})
  # update wires

  cntl0 = slctBts(rgIn, 14, 14)
  cmpl0In = slctBts(rgIn, 14, 2)
  cmpl0Out = oneCmpl(cntl0, cmpl0In)

  addr2Out = addSgnl(rgsA2Sin[2], rgsA2Sin[4])

  cntl1 = slctBts(rgsA2Sin[6], 0, 0)
  cmpl1In = addr2Out
  cmpl1Out = oneCmpl(cntl1, cmpl1In)

  # from output to input update registers
  rgOutIn = mkBus(rgsA2Sin[6], (0,0), cmpl1Out, (10,0))
  rgsA2Sin[7] = rgOutIn

  rgsA2Sin[6] = rgsA2Sin[5]
  rgsA2Sin[5] = slctBts(rgIn, 15, 15)

  rgsA2Sin[2] = rgsA2Sin[1]
  rgsA2Sin[1] = rom0Mem(mkBus(cmpl0Out, (11,4), nullBus, (0,0)))

  rgsA2Sin[4] = rgsA2Sin[3]
  rgsA2Sin[3] = rom1Mem(mkBus(cmpl0Out, (11,8), cmpl0Out, (3,0)))
  return rgsA2Sin
end

sineOut = Wr(12,0,rgOutInit)

accmDlt = trunc(UInt32, (2^20)/16) # 65536
accm0Dlt = GetRg((accmDlt>>4)&0xFFFF)
accm1Dlt = GetRg((accmDlt)&0xF)

#########################################################################
npts = 262144
# npts = 4096
sineOut = Vector{Int64}(undef,npts)
qdOut = Vector{Complex}(undef, npts)

@time begin
for i in 1:npts
  global rgAccm0r,rgAccm1r,rgAccm0q,rgAccm1q
  global wrFreq,rgsAccmQd,rgsA2Sinr,rgsA2Sinq,sineOut

  qdOut[i] = GetVl(rgsA2Sinr[7]) + 1im*GetVl(rgsA2Sinq[7])
  @bp

  rgsA2Sinr = updA2Sin!(rgAccm0r, rgsA2Sinr)
  rgsA2Sinq = updA2Sin!(rgAccm0q, rgsA2Sinq)

  aa = 1;

  # Update Input Accumulators
  (rgAccm0r, rgAccm1r, rgAccm0q, rgAccm1q) = 
    updQdAccum!(wrFreq, rgAccm0r, rgAccm1r, rgAccm0q, rgAccm1q)

  aa = 1;
end
#######################################################################
end # @time
@time begin
npts = 262144
# npts = 4096
sineOut = Vector{Int64}(undef,npts)
for i in 1:npts
  global rgAccm0,rgAccm1,sineOut,wrFreq,rgsA2Sin

  sineOut[i] = GetVl(@out())
  @bp

  rgsA2Sin = updA2Sin!(rgAccm0, rgsA2Sin)
  aa = 1;

  # Update Input Accumulators
  (rgAccm0, rgAccm1) = updAccum!(wrFreq, rgAccm0, rgAccm1)

  aa = 1;
end
end # @time end
aa = 1;

##################################################################


osc1 = initOsc(1/16, 12);

osc2 = initOsc(1/16, 16);

#= Commented out for now as we are doing DDFS
for i = 0:8191
  xr, xq = updOsc(osc2)
  println("i: $(i): xr: $(real(xr)), xq: $(real(xq))")
  a = 1
end
=#

__init__()
end
