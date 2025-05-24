-- ID = 88888890
local s,id=GetID()
function s.initial_effect(c)
	 -- Synchro Summon: 1 Tuner + 1 non-Tuner Warrior Synchro Monster
	aux.AddSynchroProcedure(c, nil,
		aux.NonTuner(function(c)
			return c:IsType(TYPE_SYNCHRO) and c:IsRace(RACE_WARRIOR)
		end),
	1)
	c:EnableReviveLimit()
	-- (1) If this card is Special Summoned during the Battle Phase: negate all face-up opponent cards
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DISABLE)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	-- (2) This card can attack while in face-up Defense Position, and uses its DEF for damage
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_DEFENSE_ATTACK)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	-- (3) Extra attacks: total Normal Monsters you control or in your GY
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_EXTRA_ATTACK)
	e3:SetValue(s.atkval)
	c:RegisterEffect(e3)

	-- (4) Cannot be destroyed by battle
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_SINGLE)
	e6:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e6:SetRange(LOCATION_MZONE)
	e6:SetCode(EFFECT_INDESTRUCTABLE_BATTLE)
	e6:SetValue(1)
	c:RegisterEffect(e6)
	-- (4) At the end of the Damage Step, when this card attacks an opponent's monster, but the opponent's monster was not destroyed by the battle: You can banish that opponent's monster.
	local e7=Effect.CreateEffect(c)
	e7:SetDescription(aux.Stringid(2129638,0))
	e7:SetCategory(CATEGORY_REMOVE)
	e7:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e7:SetCode(EVENT_DAMAGE_STEP_END)
	e7:SetCondition(s.rmcon)
	e7:SetTarget(s.rmtg)
	e7:SetOperation(s.rmop)
	c:RegisterEffect(e7)
end

-- (1) Condition: Synchro Summoned during Battle Phase
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	local ph=Duel.GetCurrentPhase()
	return e:GetHandler():IsSummonType(SUMMON_TYPE_SPECIAL)
	   and (ph>=PHASE_BATTLE_START and ph<=PHASE_BATTLE)
end

-- (1) Target: any face-up card opponent controls
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, 1, nil)
	end
	local g=Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, nil)
	Duel.SetOperationInfo(0, CATEGORY_DISABLE, g, #g, 0, 0)
end

-- (1) Operation: negate their effects
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsFaceup, tp, 0, LOCATION_ONFIELD, nil)
	for tc in aux.Next(g) do
		Duel.NegateRelatedChain(tc, RESET_TURN_SET)
		local d1=Effect.CreateEffect(c)
		d1:SetType(EFFECT_TYPE_SINGLE)
		d1:SetCode(EFFECT_DISABLE)
		d1:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(d1)
		local d2=Effect.CreateEffect(c)
		d2:SetType(EFFECT_TYPE_SINGLE)
		d2:SetCode(EFFECT_DISABLE_EFFECT)
		d2:SetValue(RESET_TURN_SET)
		d2:SetReset(RESET_EVENT+RESETS_STANDARD)
		tc:RegisterEffect(d2)
	end
end

-- (3) Calculate extra attacks: the number of "NTN, The Captain of Hyperion" you control or have in your Graveyard minus 1.
function s.atkval(e,c)
	local tp = c:GetControler()
	-- Số lá 88888800 trên sân
	local countField=Duel.GetMatchingGroupCount(Card.IsCode,tp,LOCATION_MZONE,0,nil,88888800)
	-- Số lá 88888800 trong mộ
	local countGrave=Duel.GetMatchingGroupCount(Card.IsCode,tp,LOCATION_GRAVE,0,nil,88888800)
	local total = countField + countGrave
	if total < 1 then
		return 0
	else
		return total - 1
	end
end

function s.rmcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local bc=c:GetBattleTarget()
	e:SetLabelObject(bc)
	return c==Duel.GetAttacker() and aux.dsercon(e,tp,eg,ep,ev,re,r,rp)
		and bc and c:IsStatus(STATUS_OPPO_BATTLE) and bc:IsOnField() and bc:IsRelateToBattle()
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetLabelObject():IsAbleToRemove() end
	Duel.SetOperationInfo(0,CATEGORY_REMOVE,e:GetLabelObject(),1,0,0)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	local bc=e:GetLabelObject()
	if bc:IsRelateToBattle() then
		Duel.Remove(bc,POS_FACEUP,REASON_EFFECT)
	end
end