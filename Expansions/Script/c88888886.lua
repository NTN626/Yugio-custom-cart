local s,id=GetID()
function s.initial_effect(c)
	-- (1) Quick Effect: When opponent Special Summons during your Main Phase 1
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetRange(LOCATION_HAND)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

-- (1) Condition: it must be Main Phase 1 and opponent just Special Summoned
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	if ph~=PHASE_MAIN1 then return false end
	return eg:IsExists(function(c)
		return c:GetSummonPlayer()==1-tp
		   and c:IsSummonType(SUMMON_TYPE_SPECIAL)
	end,1,nil)
end

-- (1) Target: you have ≥2 monster zones & can SS this + 1 “valkyrie” from Deck/GY
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
		   and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
		   and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

-- (1) Filter: “valkyrie” Dragons
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x929) and c:IsRace(RACE_WARRIOR) and c:IsLevel(8)
	   and c:IsCanBeSpecialSummoned(e,0,tp,false,false) 
end

-- (1) Operation: SS this + chosen “Blue-Eyes”, then immediately Synchro Summon
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or not c:IsRelateToEffect(e) then return end
	-- Choose a “Blue-Eyes” Dragon from Deck/GY
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #tg==0 then return end
	local bc=tg:GetFirst()
	-- Special Summon both monsters
	Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP)
	Duel.SpecialSummonStep(bc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SpecialSummonComplete()
	Duel.BreakEffect()
	-- Gather the two into a group for Synchro Summon
	local mg=Group.CreateGroup()
	mg:AddCard(c)
	mg:AddCard(bc)
	-- Prompt for a Synchro Monster summonable with these materials
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,
		function(sc)
			return sc:IsType(TYPE_SYNCHRO)
			   and sc:IsSynchroSummonable(nil,mg)
		end,
		tp,LOCATION_EXTRA,0,1,1,nil)
	if #sg>0 then
		Duel.SynchroSummon(tp,sg:GetFirst(),nil,mg)
	end
end
