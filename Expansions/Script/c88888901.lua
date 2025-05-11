local s,id=GetID()
function s.initial_effect(c)
	-- Effect 1: Fusion Summon 1 Fusion Monster
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_FUSION_SUMMON+CATEGORY_TODECK)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.fuscon)
	e1:SetTarget(s.fustg)
	e1:SetOperation(s.fusop)
	c:RegisterEffect(e1)

	-- Effect 2: GY Quick — in opponent’s Main Phase,
	-- shuffle this card + 1 “Flame Chasers” S/T in your GY or banished,
	-- then shuffle 1 face-up S/T your opponent controls
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,88888815)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_MAIN_END)
	e2:SetCondition(function(e,tp)
		local ph=Duel.GetCurrentPhase()
		return Duel.GetTurnPlayer()~=tp
		   and (ph==PHASE_MAIN1 or ph==PHASE_MAIN2)
	end)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e2:SetTarget(s.gravtg)
	e2:SetOperation(s.gravop)
	c:RegisterEffect(e2)
end

-- ===== Effect 1 Helpers =====

-- Only in your Main Phase
function s.fuscon(e,tp)
	local ph=Duel.GetCurrentPhase()
	return ph==PHASE_MAIN1 or ph==PHASE_MAIN2
end
-- materials filter
function s.matfilter(c,e)
	return c:IsType(TYPE_MONSTER)
	   and c:IsAbleToDeck()
	   and not c:IsImmuneToEffect(e)
end
-- valid Fusion targets
function s.spfilter(c,e,tp,m,chkf)
	if not (c:IsRace(RACE_WARRIOR) and c:IsType(TYPE_FUSION)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_FUSION,tp,false,false)) then 
		return false 
	end
	-- require at least one Normal among materials
	aux.FCheckAdditional = function(tp,sg,fc)
		return sg:IsExists(Card.IsType,1,nil,TYPE_NORMAL)
	end
	local res = c:CheckFusionMaterial(m,nil,chkf)
	aux.FCheckAdditional = nil
	return res
end

-- Effect 1 target
function s.fustg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		local chkf = tp
		local mg = Duel.GetMatchingGroup(aux.NecroValleyFilter(s.matfilter),tp,
						LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e)
		return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp,mg,chkf)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,
		LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED)
end

-- Effect 1 operation
function s.fusop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end
	local chkf=tp
	local mg=Duel.GetMatchingGroup(aux.NecroValleyFilter(s.matfilter),tp,
		LOCATION_ONFIELD+LOCATION_GRAVE+LOCATION_REMOVED,0,nil,e)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg1=Duel.GetMatchingGroup(s.spfilter,tp,LOCATION_EXTRA,0,nil,e,tp,mg,chkf)
	if sg1:GetCount()==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local fc=sg1:Select(tp,1,1,nil):GetFirst()
	aux.FCheckAdditional = function(tp,sg,fc)
		return sg:IsExists(Card.IsType,1,nil,TYPE_NORMAL)
	end
	local mat = Duel.SelectFusionMaterial(tp,fc,mg,nil,chkf)
	aux.FCheckAdditional = nil
	if not mat or mat:GetCount()==0 then return end
	 fc:SetMaterial(mat)
	Duel.SendtoDeck(mat,nil,SEQ_DECKSHUFFLE,
		REASON_EFFECT+REASON_MATERIAL+REASON_FUSION)
	Duel.BreakEffect()
	Duel.SpecialSummon(fc,SUMMON_TYPE_FUSION,tp,tp,false,false,POS_FACEUP)
	fc:CompleteProcedure()
end

-- ===== Effect 2 Helpers =====

-- filter your “Primite” S/T except this card
function s.primstfilter(c)
	return c:IsSetCard(0x8b4)
	   and c:IsType(TYPE_SPELL+TYPE_TRAP)
	   and c:IsAbleToDeck()
	   and c:GetCode()~=id
end

-- Effect 2 target: pick 1 Primite S/T in your GY/banished + 1 face-up S/T your opponent controls
function s.gravtg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return false end
	if chk==0 then
		return Duel.IsExistingTarget(s.primstfilter,tp,
				   LOCATION_GRAVE+LOCATION_REMOVED,0,1,nil)
		   and Duel.IsExistingTarget(s.opstfilter,tp,0,LOCATION_SZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g1=Duel.SelectTarget(tp,s.primstfilter,tp,
		LOCATION_GRAVE+LOCATION_REMOVED,0,1,1,nil)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local g2=Duel.SelectTarget(tp,s.opstfilter,tp,0,
		LOCATION_SZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g1,1,tp,
		LOCATION_GRAVE+LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,g2,1,1-tp,
		LOCATION_SZONE)
end

-- Effect 2 operation: shuffle the two targets + this card itself
function s.gravop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tg=Duel.GetChainInfo(0,CHAININFO_TARGET_CARDS)
			 :Filter(Card.IsRelateToEffect,nil,e)
	if #tg<2 then return end
	tg:AddCard(c)
	Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
end