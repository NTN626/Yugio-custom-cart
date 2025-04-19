--Blue-Eyjgvhhes Chaos Dragon
local c24382602,id,o=GetID()
--光の霊堂
function c24382602.initial_effect(c)
	-- Activate
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	c:RegisterEffect(e1)
	-- extra summon: During your Main Phase, you can Normal Summon 1 Level 1 LIGHT Tuner 
	-- in addition to your Normal Summon/Set. (Once per turn)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(24382602,0))
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_EXTRA_SUMMON_COUNT)
	e2:SetRange(LOCATION_FZONE)
	e2:SetTargetRange(LOCATION_HAND+LOCATION_MZONE,0)
	e2:SetTarget(c24382602.extg)
	c:RegisterEffect(e2)
	-- ATK/DEF boost effect: Once per turn, target 1 face-up monster you control;
	-- send 1 Normal Monster from your hand or Deck to the GY, and if you do, 
	-- that monster gains ATK/DEF equal to the Level of the sent monster x 100, 
	-- until the end of this turn (even if this card leaves the field).
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_IGNITION)
	e3:SetRange(LOCATION_FZONE)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1)
	e3:SetTarget(c24382602.atktg)
	e3:SetOperation(c24382602.atkop)
	c:RegisterEffect(e3)
	-- to hand: You can banish this card from your GY; add 1 "Level 1 LIGHT Tuner" from your Deck to your hand.
	local e4=Effect.CreateEffect(c)
	e4:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE)
	e4:SetCost(aux.bfgcost)
	e4:SetTarget(c24382602.thtg)
	e4:SetOperation(c24382602.thop)
	c:RegisterEffect(e4)
	-- Return banished: During the End Phase, if this card is banished, 
	-- return it to the bottom of your Deck.
	local e5=Effect.CreateEffect(c)
	e5:SetDescription(aux.Stringid(24382602,3))
	e5:SetCategory(CATEGORY_TODECK)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetRange(LOCATION_REMOVED)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetCountLimit(1)
	e5:SetTarget(c24382602.rettg)
	e5:SetOperation(c24382602.retop)
	c:RegisterEffect(e5)
end

function c24382602.extg(e,c)
	return c:IsType(TYPE_TUNER) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsLevel(1)
end

function c24382602.tgfilter(c)
	return c:IsFaceup()
end

function c24382602.filter(c)
	return c:IsType(TYPE_NORMAL) and c:IsType(TYPE_MONSTER) and c:IsAbleToGrave()
end

function c24382602.atktg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_MZONE) and chkc:IsControler(tp) and c24382602.tgfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(c24382602.tgfilter,tp,LOCATION_MZONE,0,1,nil)
		 and Duel.IsExistingMatchingCard(c24382602.filter,tp,LOCATION_DECK+LOCATION_HAND,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
	Duel.SelectTarget(tp,c24382602.tgfilter,tp,LOCATION_MZONE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

function c24382602.atkop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,c24382602.filter,tp,LOCATION_DECK+LOCATION_HAND,0,1,1,nil)
	if #g>0 then
		local gc=g:GetFirst()
		local lv=gc:GetLevel()
		if Duel.SendtoGrave(gc,REASON_EFFECT)~=0 and gc:IsLocation(LOCATION_GRAVE) and tc:IsRelateToEffect(e) and tc:IsFaceup() then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetType(EFFECT_TYPE_SINGLE)
			e1:SetCode(EFFECT_UPDATE_ATTACK)
			e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
			e1:SetValue(lv*100)
			tc:RegisterEffect(e1)
			local e2=e1:Clone()
			e2:SetCode(EFFECT_UPDATE_DEFENSE)
			tc:RegisterEffect(e2)
		end
	end
end

-- New thfilter: Filter for a Level 1 LIGHT Tuner from the Deck.
function c24382602.thfilter(c)
	return c:IsLevel(1) and c:IsAttribute(ATTRIBUTE_LIGHT) and c:IsType(TYPE_TUNER) and c:IsAbleToHand()
end

function c24382602.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(c24382602.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

function c24382602.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,c24382602.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if g:GetCount()>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- End Phase effect: Return this banished card to the bottom of the Deck.
function c24382602.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
end

function c24382602.retop(e,tp,eg,ep,ev,re,r,rp)
	if e:GetHandler():IsRelateToEffect(e) then
		Duel.SendtoDeck(e:GetHandler(),nil,SEQ_DECKBOTTOM,REASON_EFFECT)
	end
end
