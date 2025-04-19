--Blue-Eyes Chaos Dragon
local s,id,o=GetID()
function s.initial_effect(c)
	aux.AddSynchroProcedure(c,nil,aux.NonTuner(Card.IsSetCard,0xdd),1)
	c:EnableReviveLimit()
	 -- Effect 1: If this card is Special Summoned: You can negate the effects of all face-up cards your opponent currently controls.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(9999992,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(c9999992.spcon)
	e1:SetTarget(c9999992.sptg)
	e1:SetOperation(c9999992.spop)
	c:RegisterEffect(e1)
	-- Effect 2: This card can attack while in face-up Defense Position, and use its DEF for damage calculation.
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DEFENSE_ATTACK)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	-- Effect 3: This card can attack a number of times each Battle Phase equal to the number of Normal Monsters you control or have in your Graveyard.
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetValue(c9999992.atkval)
	c:RegisterEffect(e3)
end

-- Effect 1 condition: Check if this card was Special Summoned.
function c9999992.spcon(e,tp,eg,ep,ev,re,r,rp)
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
end

-- Effect 1 target: All face-up cards your opponent currently controls.
function c9999992.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil)
	end
	local g=Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, #g, 0, 0)
end

-- Effect 1 operation: Negate the effects of all face-up cards your opponent currently controls.
function c9999992.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, nil)
	if #g==0 then return end
	for tc in aux.Next(g) do
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_DISABLE)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e1)
		local e2=Effect.CreateEffect(c)
		e2:SetType(EFFECT_TYPE_SINGLE)
		e2:SetCode(EFFECT_DISABLE_EFFECT)
		e2:SetValue(RESET_TURN_SET)
		e2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(e2)
	end
end

-- Effect 3: Calculate extra attacks: the number of Normal Monsters you control or have in your Graveyard minus 1.
function c9999992.atkval(e,c)
	local tp = c:GetControler()
	local countField = Duel.GetMatchingGroupCount(
		function(card)
			return card:IsFaceup() and card:IsType(TYPE_NORMAL)
		end, tp, LOCATION_MZONE, 0, nil)
	local countGrave = Duel.GetMatchingGroupCount(Card.IsType, tp, LOCATION_GRAVE, 0, nil, TYPE_NORMAL)
	local total = countField + countGrave
	if total < 1 then
		return 0
	else
		return total - 1
	end
end