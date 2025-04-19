-- 白き龍の威光
local s,id=GetID()
function s.initial_effect(c)
	aux.AddCodeList(c,89631139)
	-- Effect 1: Show up to 3 “Blue‑Eyes White Dragon” in your hand, face‑up Monster Zone, and/or GY; 
	-- then destroy an equal number of cards your opponent controls.
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
	-- Effect 2: GY Quick — if this card is in your GY (except the turn it was sent there):
	-- target 1 banished Spell/Trap that mentions “Blue‑Eyes White Dragon”; 
	-- shuffle both this card and that target into the Deck, and if you do, draw 1.
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK+CATEGORY_DRAW)
	e2:SetType(EFFECT_TYPE_QUICK_O)
	e2:SetCode(EVENT_FREE_CHAIN)
	e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e2:SetRange(LOCATION_GRAVE)
	e2:SetCountLimit(1,id+100)
	e2:SetCondition(s.gravecon)
	e2:SetTarget(s.gravetg)
	e2:SetOperation(s.graveop)
	c:RegisterEffect(e2)
end

-- Effect 1 filters
function s.bewdfilter(c)
	return c:IsCode(89631139) and (c:IsLocation(LOCATION_HAND) 
		or (c:IsLocation(LOCATION_MZONE) and c:IsFaceup()) 
		or c:IsLocation(LOCATION_GRAVE))
end
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local cg=Duel.GetMatchingGroup(s.bewdfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if chk==0 then 
		return #cg>0 and Duel.IsExistingMatchingCard(nil,tp,0,LOCATION_ONFIELD,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,1-tp,LOCATION_ONFIELD)
end
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local cg=Duel.GetMatchingGroup(s.bewdfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_GRAVE,0,nil)
	if #cg==0 then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CONFIRM)
	local rg=cg:Select(tp,1,math.min(3,#cg),nil)
	-- reveal hand cards
	local hrg=rg:Filter(Card.IsLocation,nil,LOCATION_HAND)
	if #hrg>0 then
		Duel.ConfirmCards(1-tp,hrg)
	end
	-- highlight monsters
	local mgr=rg:Filter(Card.IsLocation,nil,LOCATION_MZONE)
	if #mgr>0 then
		Duel.HintSelection(mgr)
	end
	local count=#rg
	Duel.ShuffleHand(tp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local dg=Duel.SelectMatchingCard(tp,nil,tp,0,LOCATION_ONFIELD,count,count,nil)
	if #dg>0 then
		Duel.Destroy(dg,REASON_EFFECT)
	end
end

-- Condition: it’s your turn, and this card was not sent to the GY this turn
function s.gravecon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return Duel.GetTurnPlayer()==tp and c:GetTurnID()~=Duel.GetTurnCount()
end
-- filter banished Spell/Trap listing BEWD
function s.gravefilter(c)
	return c:IsFaceup() and c:IsType(TYPE_SPELL+TYPE_TRAP) 
		and aux.IsCodeListed(c,89631139) and c:IsAbleToDeck()
end
function s.gravetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then 
		return Duel.IsExistingMatchingCard(s.gravefilter,tp,LOCATION_REMOVED,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_TODECK,e:GetHandler(),1,0,0)
	Duel.SetOperationInfo(0,CATEGORY_TODECK,nil,1,tp,LOCATION_REMOVED)
	Duel.SetOperationInfo(0,CATEGORY_DRAW,nil,0,tp,1)
end
function s.graveop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TODECK)
	local tg=Duel.SelectMatchingCard(tp,s.gravefilter,tp,LOCATION_REMOVED,0,1,1,nil)
	if #tg>0 then
		tg:AddCard(c)
		Duel.SendtoDeck(tg,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
		Duel.ShuffleDeck(tp)
		Duel.BreakEffect()
		Duel.Draw(tp,1,REASON_EFFECT)
	end
end
