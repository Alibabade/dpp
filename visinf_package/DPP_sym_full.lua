
--  Copyright (c) 2018, TU Darmstadt.
--  All rights reserved.
--
--  This source code is licensed under the BSD-style license found in the
--  LICENSE file in the root directory of this source tree.

require 'paths'
require 'nn'
require 'nngraph'
require 'cutorch'
require 'cunn'
require 'cudnn'
require 'nnlr'
require 'visinf.PositiveBias'
require 'visinf.CWeightCalc'
--require 'graphviz'
local DPP_sym_full, Parent = torch.class('visinf.DPP_sym_full','nn.Sequential')


function DPP_sym_full:__init(nPlane)
   print('DPP symmetric full on board!')
   Parent.__init(self)


   local p=nn.Parallel(2,2)
   for i=1,nPlane do
   local t=nn.Sequential();t:add(nn.Unsqueeze(2));t:add(cudnn.SpatialConvolution(1,1,3,3,2,2,1,1))
      p:add(t)
   end


   local I=nn.Identity()()

   local It = I - p - nn.SpatialUpSamplingNearest(2)
   
   local x=nn.CSubTable()({I,It}) - nn.Power(2) - nn.AddConstant(1e-3,true)


   local xn=x - nn.SpatialAveragePooling(2,2,2,2) - nn.SpatialUpSamplingNearest(2)



   local w = nn.CDivTable()({x,xn})  - visinf.CWeightCalc(nPlane):weightDecay('weight',0) - visinf.PositiveBias(nPlane):weightDecay('weight',0)

   local kp= w - nn.SpatialAveragePooling(2,2,2,2)
   local Iw = nn.CMulTable()({I,w}) - nn.SpatialAveragePooling(2,2,2,2)

   local output= nn.CDivTable()({Iw,kp})
   local block=nn.gModule({I},{output})

   self:add(block)
end

