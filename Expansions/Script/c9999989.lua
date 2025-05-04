-- Custom Fusion Monster: Blue-Eyes Synchro Tyrant
-- ID = 9999988
local s,id=GetID()
function s.initial_effect(c)
	-- Fusion Materials: "Blue-Eyes White Dragon" + 1 Effect Monster on the field (either player)
	c:EnableReviveLimit()
	aux.AddFusionProcCodeFun(c,89631139,aux.FilterBoolFunction(Card.IsType,TYPE_EFFECT),1,true)

	-- Contact Fusion: send materials from hand (your hand only) or field (either player's) to GY as cost
	local function contact_op(g,tp,fc)
		Duel.SendtoGrave(g,REASON_COST+REASON_MATERIAL)
	end
	aux.AddContactFusionProcedure(c,
		s.cfilter,
		LOCATION_HAND+LOCATION_MZONE,  -- your hand and your field
		LOCATION_MZONE,			 -- opponent's field only
		contact_op
	)

	-- Special Summon Condition: only by Fusion Summon or Contact Fusion
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	c:RegisterEffect(e0)

	-- Limit one Special Summon of this card per turn
	c:SetSPSummonOnce(id)

	-- Can attack all monsters your opponent controls, once each
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetCode(EFFECT_ATTACK_ALL)
	e1:SetValue(1)
	c:RegisterEffect(e1)

	-- This card inflicts no battle damage to opponent when attacking
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_NO_BATTLE_DAMAGE)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	c:RegisterEffect(e2)

	-- Set Trap: Once per turn, at the end of the Damage Step, if this card battled: target 1 Trap in your GY; Set it
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_LEAVE_GRAVE)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetCode(EVENT_DAMAGE_STEP_END)
	e3:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e3:SetCountLimit(1,id)
	e3:SetCondition(aux.dsercon)
	e3:SetTarget(s.settg)
	e3:SetOperation(s.setop)
	c:RegisterEffect(e3)

	-- After Fusion Summon, restrict Extra Deck summons except LIGHT Dragon monsters
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCountLimit(1,id)
	e4:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION)
	end)
	e4:SetOperation(s.resop)
	c:RegisterEffect(e4)


	-- Mandatory: Destroy this card during your End Phase
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+PHASE_END)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1)
	e5:SetCondition(function(e,tp,eg,ep,ev,re,r,rp)
		return Duel.GetTurnPlayer()==tp
	end)
	e5:SetOperation(function(e,tp,eg,ep,ev,re,r,rp)
		Duel.Destroy(e:GetHandler(),REASON_EFFECT)
	end)
	c:RegisterEffect(e5)
end

-- Contact Fusion material filter: Blue-Eyes White Dragon or any Effect Monster
function s.cfilter(c)
	return (c:IsCode(89631139) or c:IsType(TYPE_EFFECT)) and c:IsAbleToGraveAsCost()
end

-- Set Trap from GY helper functions
function s.setfilter(c)
	return c:IsType(TYPE_TRAP) and c:IsSSetable()
end
function s.settg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.setfilter(chkc) end
	if chk==0 then return Duel.IsExistingTarget(s.setfilter,tp,LOCATION_GRAVE,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectTarget(tp,s.setfilter,tp,LOCATION_GRAVE,0,1,1,nil)
	Duel.SetOperationInfo(0,CATEGORY_LEAVE_GRAVE,g,1,0,0)
end
function s.setop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then Duel.SSet(tp,tc) end
end

-- Restrict Extra Deck summons
function s.resop(e,tp,eg,ep,ev,re,r,rp)
	local ex=Effect.CreateEffect(e:GetHandler())
	ex:SetType(EFFECT_TYPE_FIELD)
	ex:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	ex:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	ex:SetTargetRange(1,0)
	ex:SetTarget(function(e,c,sump,sumtype,sumpos,targetp,se)
		return c:IsLocation(LOCATION_EXTRA)
		   and (not c:IsRace(RACE_DRAGON) or not c:IsAttribute(ATTRIBUTE_LIGHT))
	end)
	ex:SetReset(RESET_PHASE+PHASE_END)
	Duel.RegisterEffect(ex,tp)
end
