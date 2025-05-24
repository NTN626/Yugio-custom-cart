-- Custom Fusion Dragon
-- Unaffected by opponent’s card effects.
-- If Fusion Summoned using “Rita Rossweisse, The Maid of Hyperion” (88888905) as material:
--   Cannot be destroyed by battle until the end of this turn.
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion materials: “NTN, The Captain of Hyperion” + 1 “Valkyrie”
	c:EnableReviveLimit()
	aux.AddFusionProcCodeFun(c,88888800,aux.FilterBoolFunction(Card.IsSetCard,0x929),1,true)
	-- (1) Immunity to opponent’s effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)
	-- (2) If Fusion Summoned with Rita Rossweisse as material: battle indestructible
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetCondition(s.indcond)
	e2:SetOperation(s.indop)
	c:RegisterEffect(e2)
end

-- Filter out opponent’s effects
function s.efilter(e,te)
	return te:GetHandler()~=e:GetHandler()
end

-- Condition: Fusion Summoned and material included Rita Rossweisse
function s.indcond(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	return c:IsSummonType(SUMMON_TYPE_FUSION)
	   and c:GetMaterial():IsExists(Card.IsOriginalCodeRule,1,nil,88888905)
end

-- Operation: cannot be destroyed by battle until end of turn
function s.indop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if not c:IsRelateToEffect(e) then return end
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e1:SetValue(1)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_END)
	c:RegisterEffect(e1)
end
