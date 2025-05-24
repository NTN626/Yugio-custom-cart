-- “NTN, The Captain of Hyperion” (Custom)
-- ID = 88888907
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion materials: “NTN, The Captain of Hyperion” + 1 “Valkyrie”
	c:EnableReviveLimit()
	aux.AddFusionProcCodeFun(c,88888800,aux.FilterBoolFunction(Card.IsSetCard,0x929),1,true)

	-- Special Summon procedure: from Extra Deck by banishing 1 Level 1 LIGHT Warrior from field or GY
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_FIELD)
	e0:SetCode(EFFECT_SPSUMMON_PROC)
	e0:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e0:SetRange(LOCATION_EXTRA)
	e0:SetCondition(s.spcon)
	e0:SetOperation(s.spop1)
	c:RegisterEffect(e0)

	-- Summon condition: must be Fusion Summoned or via above
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e1:SetCode(EFFECT_SPSUMMON_CONDITION)
	e1:SetValue(s.splimit)
	c:RegisterEffect(e1)

	-- Rita Rossweisse SS limit: You can only Special Summon Rita Rossweisse once per turn
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1,0)
	e2:SetTarget(s.rlimit)
	c:RegisterEffect(e2)

	-- Register Rita summon flag on your Summon
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetOperation(s.regop)
	c:RegisterEffect(e3)

	-- Quick Effect (Main Phase): Fusion Summon 1 Warrior Fusion (except Lubellion) by shuffling its materials
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON)
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_FREE_CHAIN)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,88888818)
	e4:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e4:SetCondition(s.fqcon)
	e4:SetTarget(s.fqtg)
	e4:SetOperation(s.fqop)
	c:RegisterEffect(e4)
end

-- SP Summon procedure: banish 1 Level 1 LIGHT Warrior
function s.spfilter(c)
	return c:IsLevel(1) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsRace(RACE_WARRIOR) and c:IsAbleToRemoveAsCost()
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
	   and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)
end
function s.spop1(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
end

-- Only via Fusion or via our special summon
function s.splimit(e,se,sp,st)
	return (st&SUMMON_TYPE_FUSION)==SUMMON_TYPE_FUSION or se==s.spop1
end

-- Rita Rossweisse limit
function s.rlimit(e,c,sump,sumtype,sumpos,targetp)
	return c:IsCode(88888905) and Duel.GetFlagEffect(e:GetHandlerPlayer(),88888905)>0
end
function s.regop(e,tp,eg,ep,ev,re,r,rp)
	-- if this card was properly Summoned
	if e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) or Duel.GetCurrentChain()==0 then
		Duel.RegisterFlagEffect(tp,88888905,RESET_PHASE+PHASE_END,0,1)
	end
end

-- Quick Fusion in Main Phase
function s.fqcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end
function s.fqfilter(c,e,tp,m,chkf)
	return c:IsRace(RACE_WARRIOR) and c:IsType(TYPE_FUSION)
	   and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)
	   and not c:IsCode(88888905)  
	   and c:CheckFusionMaterial(m,nil,chkf)
end
function s.fqtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf=tp

		local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(
			 function(c) return c:IsType(TYPE_MONSTER) and c:IsAbleToDeck() end
		), tp, LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED, 0, nil)

		return Duel.IsExistingMatchingCard(s.fqfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,
		LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED)
end
function s.fqop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local chkf=tp
	local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(
		function(c) return c:IsType(TYPE_MONSTER) and c:IsAbleToDeck() end
	), tp, LOCATION_MZONE+LOCATION_GRAVE+LOCATION_REMOVED, 0, nil)  
   
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.GetMatchingGroup(s.fqfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,chkf)
	if #sg==0 then return end
	local fc=sg:Select(tp,1,1,nil):GetFirst()
	aux.FCheckAdditional = nil
	local mat=Duel.SelectFusionMaterial(tp,fc,mg,nil,chkf)
	if not mat or mat:GetCount()==0 then return end
	fc:SetMaterial(mat)
	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	fc:CompleteProcedure()
end
