--Shaman with eyes of Blue
-- Custom Quick‑Synchro Support Tuner
-- ID = 9999994 (thay bằng ID bạn chọn)
local s,id=GetID()
function s.initial_effect(c)
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

-- (1) Quick Effect: During either player’s Main Phase, when your opponent Special Summons a monster…
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	if ph~=PHASE_MAIN1 then return false end
	return eg:IsExists(function(c)
		return c:GetSummonPlayer()==1-tp 
		   and c:IsSummonType(SUMMON_TYPE_SPECIAL)
	end, 1, nil)
end

-- Target: you have ≥2 free zones, you can SS this and 1 “Blue‑Eyes” from Deck/GY
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>=2
		   and e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false)
		   and Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_GRAVE)
end

-- Filter: “Blue‑Eyes” Dragon in Deck or GY
function s.spfilter(c,e,tp)
	return c:IsSetCard(0xdd) and c:IsRace(RACE_DRAGON)
	   and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<2 or not c:IsRelateToEffect(e) then return end
	-- Chọn 1 “Blue‑Eyes” Dragon từ Deck/GY
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local tg=Duel.SelectMatchingCard(tp, s.spfilter, tp, LOCATION_DECK+LOCATION_GRAVE, 0, 1, 1, nil, e, tp)
	if #tg==0 then return end
	local bc=tg:GetFirst()
	-- Special Summon cả 2
	Duel.SpecialSummonStep(c,0,tp,tp,false,false,POS_FACEUP)
	Duel.SpecialSummonStep(bc,0,tp,tp,false,false,POS_FACEUP)
	Duel.SpecialSummonComplete()
	-- Tách hiệu ứng
	Duel.BreakEffect()
	-- Tạo nhóm gồm 2 quái đã SS
	local mg=Group.CreateGroup()
	mg:AddCard(c)
	mg:AddCard(bc)
	-- Chọn Synchro Monster có thể Summon đúng với 2 quái này
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(tp,
		function(sc) return sc:IsType(TYPE_SYNCHRO)
			and sc:IsSynchroSummonable(nil,mg) end,
		tp,LOCATION_EXTRA,0,1,1,nil)
	if #sg>0 then
		Duel.SynchroSummon(tp, sg:GetFirst(), nil, mg)
	end
end