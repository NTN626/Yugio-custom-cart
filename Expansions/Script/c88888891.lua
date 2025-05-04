--碧鋼の機竜 (Custom)
local s,id=GetID()
function s.initial_effect(c)
	-- Synchro Summon: 1 Tuner + 1 non-Tuner Warrior Synchro Monster
	aux.AddSynchroProcedure(c, nil,
		aux.NonTuner(function(c)
			return c:IsType(TYPE_SYNCHRO) and c:IsRace(RACE_WARRIOR)
		end),
	1)
	c:EnableReviveLimit()
	-- Effect 1: When this card is Special Summoned: Target 1 Special Summoned monster your opponent controls; return that target to the hand.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_CARD_TARGET)
	e1:SetTarget(s.rettg)
	e1:SetOperation(s.retop)
	c:RegisterEffect(e1)
	-- Effect 2: Face-up cards in your Spell & Trap Zone cannot be destroyed by card effects.
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD)
	e3:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e3:SetRange(LOCATION_MZONE)
	e3:SetTargetRange(LOCATION_SZONE,0)
	e3:SetTarget(function(e,cc) return cc:IsFaceup() end)
	e3:SetValue(1)
	c:RegisterEffect(e3)
	-- Effect 3: When this Synchro Summoned card is destroyed by card effect and sent to the GY:
	-- You can add 1 Level 1 LIGHT Tuner from your Deck or your GY to your hand.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_TO_GRAVE)
	e2:SetCountLimit(1,88888805)
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Effect 1
function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then 
		return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(1-tp)
		   and chkc:IsFaceup() and chkc:IsSummonType(SUMMON_TYPE_SPECIAL)
	end
	if chk==0 then 
		return Duel.IsExistingTarget(s.retfilter,tp,0,LOCATION_MZONE,1,nil)
	end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RTOHAND)
	local g=Duel.SelectTarget(tp,s.retfilter,tp,0,LOCATION_MZONE,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,g,1,0,0)
end
function s.retfilter(c)
	return c:IsFaceup() and c:IsSummonType(SUMMON_TYPE_SPECIAL) and c:IsAbleToHand()
end
function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
	end
end

-- Effect 3 condition
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsReason(REASON_DESTROY) and c:IsReason(REASON_EFFECT)
	   and c:IsPreviousLocation(LOCATION_MZONE)
end
-- Filter: Level 1, LIGHT, Tuner, can be added to hand
function s.thfilter(c)
	return c:IsLevel(1) and c:IsAttribute(ATTRIBUTE_LIGHT)
	   and c:IsType(TYPE_TUNER) and c:IsAbleToHand()
end
-- Target: check for at least 1 matching card in Deck or GY
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK+LOCATION_GRAVE)
end
-- Operation: select 1 card, add to hand, reveal to opponent
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end
