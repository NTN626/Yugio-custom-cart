-- Primite Genesis & Oblivion
local s,id=GetID()  -- id == 9999998
function s.initial_effect(c)
	-- (0) Always treated as “Primite”
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x1b9)
	c:RegisterEffect(e0)

	-- (1) Add 1 “Primite” monster from Deck to hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_TOHAND+CATEGORY_SEARCH)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- (2) GY Ignition: banish self; send 1 Normal or “Primite” monster + 1 “Primite” Spell/Trap except this card from Deck → GY/hand
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOGRAVE+CATEGORY_TOHAND)
	e2:SetType(EFFECT_TYPE_IGNITION)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+1000)
	e2:SetCost(aux.bfgcost)
	e2:SetTarget(s.sendtg)
	e2:SetOperation(s.sendop)
	c:RegisterEffect(e2)
end

-- (1) Search “Primite” monster
function s.thfilter(c)
	return c:IsSetCard(0x1b9) and c:IsType(TYPE_MONSTER) and c:IsAbleToHand()
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
	if #g>0 then
		Duel.SendtoHand(g,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,g)
	end
end

-- (2) Filters
function s.sendfilter1(c)
	return (c:IsType(TYPE_NORMAL) or (c:IsSetCard(0x1b9) and c:IsType(TYPE_MONSTER)))
	   and c:IsAbleToGrave()
end
function s.sendfilter2(c)
	return c:IsSetCard(0x1b9) and c:IsType(TYPE_SPELL+TYPE_TRAP)
	   and c:IsAbleToHand() and not c:IsCode(id)
end

-- (2) Target
function s.sendtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.sendfilter1,tp,LOCATION_DECK,0,1,nil)
		   and Duel.IsExistingMatchingCard(s.sendfilter2,tp,LOCATION_DECK,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
end

-- (2) Operation
function s.sendop(e,tp,eg,ep,ev,re,r,rp)
	-- already banished by cost
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.sendfilter1,tp,LOCATION_DECK,0,1,1,nil)
	if #g1==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g2=Duel.SelectMatchingCard(tp,s.sendfilter2,tp,LOCATION_DECK,0,1,1,nil)
	if #g2==0 then return end
	Duel.SendtoGrave(g1,REASON_EFFECT)
	Duel.SendtoHand(g2,nil,REASON_EFFECT)
	Duel.ConfirmCards(1-tp,g2)
end
