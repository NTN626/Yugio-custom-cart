-- Eyes of Blue Rise
-- ID = 9999995
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,88888800)  
	aux.AddCodeList(c,88888896)  

	-- (1) Activate: Special Summon 1 Tuner from your GY in Defense
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetCountLimit(1,id+EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)

	-- (2) Destroy Replace from GY
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EFFECT_DESTROY_REPLACE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetTarget(s.reptg)
	e2:SetValue(s.repval)
	e2:SetOperation(s.repop)
	c:RegisterEffect(e2)
end

-- (1) Filter for Tuner in GY
function s.filter(c,e,tp)
	return c:IsType(TYPE_TUNER)
	   and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)
end
-- (1) Target
function s.target(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(tp)
		   and chkc:IsLocation(LOCATION_GRAVE)
		   and s.filter(chkc,e,tp)
	end
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		   and Duel.IsExistingTarget(s.filter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	Duel.SelectTarget(tp,s.filter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
-- (1) Operation
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()
	if not tc or not tc:IsRelateToEffect(e) then return end
	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP_DEFENSE)==0 then return end
	-- Restrict Extra Deck Summons to LIGHT WARRIOR Monsters only
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetDescription(aux.Stringid(id,1))
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.sumlimit)
	e1:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.sumlimit(e,c,sump,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA)
	   and not (c:IsRace(RACE_WARRIOR) and c:IsAttribute(ATTRIBUTE_LIGHT))
end

-- (2) Replacement filter: Level 9 WARRIO Synchro or “Crimson Dragon”
function s.repfilter(c,tp)
	return c:IsFaceup()
	   and c:IsControler(tp)
	   and ( c:IsCode(88888896)  
		 or (c:IsRace(RACE_WARRIOR) and c:IsType(TYPE_SYNCHRO) and c:IsLevel(9)) )
	   and c:IsReason(REASON_BATTLE+REASON_EFFECT)
	   and not c:IsReason(REASON_REPLACE)
end
-- (2) Replace destroy target
function s.reptg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	if chk==0 then
		return c:IsAbleToRemove()
		   and eg:IsExists(s.repfilter,1,nil,tp)
	end
	return Duel.SelectEffectYesNo(tp,c,96)
end
function s.repval(e,c)
	return s.repfilter(c,e:GetHandlerPlayer())
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Remove(e:GetHandler(),POS_FACEUP,REASON_EFFECT+REASON_REPLACE)
end
