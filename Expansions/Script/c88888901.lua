local s,id=GetID()
function s.initial_effect(c)
	-- Activate: Pay 2000 LP, declare 1 Normal Monster name; Special Summon that Normal Monster from your Deck in Defense Position,
	-- but you cannot Special Summon monsters this turn, except Beast monsters with the declared monster’s Attribute.
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCost(s.cost)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
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

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,1000) end
	Duel.PayLPCost(tp,1000)
end

-- Target: declare a Normal Monster name, ensure one exists
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return true end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_CODE)
	getmetatable(e:GetHandler()).announce_filter={TYPE_MONSTER,OPCODE_ISTYPE,TYPE_NORMAL,OPCODE_ISTYPE,5405694,OPCODE_ISCODE,OPCODE_OR,OPCODE_AND}
	local ac=Duel.AnnounceCard(tp,table.unpack(getmetatable(e:GetHandler()).announce_filter))
	Duel.SetTargetParam(ac)
	Duel.SetOperationInfo(0,CATEGORY_ANNOUNCE,nil,0,tp,0)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

-- Filter: match declared code, Normal, Defense pos
function s.ptfilter(e,c)
	return (c:IsCode(e:GetLabel()) and c:IsType(TYPE_NORMAL))
end
function s.smfilter(c,e,tp,code)
	return c:IsCode(code) and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) and c:IsType(TYPE_NORMAL)
end

-- Activate: do the Special Summon + impose restriction
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	local code=Duel.GetChainInfo(0,CHAININFO_TARGET_PARAM)
	-- (1) Grant battle indestructible
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetTargetRange(LOCATION_MZONE,0)
	e1:SetTarget(s.ptfilter)
	e1:SetValue(1)
	e1:SetLabel(code)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END+RESET_OPPO_TURN)
	Duel.RegisterEffect(e1,tp)
	-- (2) Special Summon luôn (bỏ điều kiện field trống)
	if Duel.IsExistingMatchingCard(s.smfilter,tp,LOCATION_DECK,0,1,nil,e,tp,code)then
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.SelectMatchingCard(tp,s.smfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp,code)
		if #g>0 then
			 
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP_DEFENSE)
			local tc=g:GetFirst()
			local attr=tc:GetAttribute()
			local er=Effect.CreateEffect(e:GetHandler())
			er:SetType(EFFECT_TYPE_FIELD)
			er:SetCode(EFFECT_CANNOT_SUMMON)
			er:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_OATH)
			er:SetTargetRange(1,0)
			er:SetTarget(function(e,c) return not c:IsAttribute(attr) end)
			er:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(er,tp)
		end
	end
end
-- ===== Effect 2 Helpers =====

-- filter your “Flame Chasers” S/T except this card
function s.primstfilter(c)
	return c:IsSetCard(0x8b4)
	   and c:IsType(TYPE_SPELL+TYPE_TRAP)
	   and c:IsAbleToDeck()
	   and c:GetCode()~=id
end

-- Effect 2 target: pick 1 Flame Chasers S/T in your GY/banished + 1 face-up S/T your opponent controls
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