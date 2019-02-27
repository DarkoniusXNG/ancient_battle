-- XNG random:
-- chance increases by an increment if false
-- chance decreases by an increment if true.
-- Resets the chance to starting percentage if there are 2 consecutive true/false.
-- If the chance is increased to 100% or above, chance is reset to starting percentage.
-- If the chance is decreased to 0% or below, chance is reset to starting percentage.
-- Has 3 counters:
-- 1) XNG_counter increases/decreases the starting percentage by an increment.
-- 2) XNG_success_counter counts how many times this function returned true in a row.
-- 3) XNG_fail_counter counts how many times this function returned false in a row.
function CDOTA_Ability_Lua:XNGRandom(percentage)
	local increment = 5
	local max_number_of_successes = 2
	local max_number_of_failures = 2

	if self.XNG_counter == nil then
		self.XNG_counter = 0
	end

	if self.XNG_success_counter == nil then
		self.XNG_success_counter = 0
	end

	if self.XNG_fail_counter == nil then
		self.XNG_fail_counter = 0
	end

	local new_percentage = percentage + self.XNG_counter

	-- Reset the counters if new percentage reached upper or lower limit
	if new_percentage >= 100 then
		self.XNG_counter = 0
		self.XNG_success_counter = 0
		self.XNG_fail_counter = 0
		return true
	elseif new_percentage <= 0 then
		self.XNG_counter = 0
		self.XNG_success_counter = 0
		self.XNG_fail_counter = 0
		return false
	end

	-- Reset the counters if someone is too lucky (consecutive successes) or too unlucky (consecutive failures)
	if self.XNG_success_counter > max_number_of_successes-1 or self.XNG_fail_counter > max_number_of_failures-1 then
		self.XNG_counter = 0
		self.XNG_success_counter = 0
		self.XNG_fail_counter = 0
	end

	if RollPercentage(new_percentage) then
		-- Decreasing the chance for next check
		self.XNG_counter = self.XNG_counter - increment	

		-- Increasing success counter
		self.XNG_success_counter = self.XNG_success_counter + 1

		--Reset the fail counter
		self.XNG_fail_counter = 0

		return true
	else
		-- Increasing the chance for next check
		self.XNG_counter = self.XNG_counter + increment

		-- Increasing fail counter
		self.XNG_fail_counter = self.XNG_fail_counter + 1

		-- Reset the success counter
		self.XNG_success_counter = 0

		return false
	end
end

-- Pseudo Random:
-- Its not the same pseudo-random as in DotA
-- starting chance is actually lower than the percentage. Example: If percentage is 25%, starting chance is 6.25%
-- Chance is increased every time this function returns false. 
-- Chance increment is equal to starting chance. If percentage is 25%, chance increment is 6.25%
-- If the chance is increased to 100% or above, chance and counter are reset.
function CDOTA_Ability_Lua:PseudoRandom(percentage)
	if self.PR_counter == nil then
		self.PR_counter = 0
	end
	
	local actual_percentage = percentage*percentage/100

	local new_percentage = math.floor(actual_percentage + self.PR_counter)

	-- Reset the counters if new percentage reached an upper limit
	if new_percentage >= 100 then
		self.PR_counter = 0
		return true
	end

	if RollPercentage(new_percentage) then
		--Reset the counter
		self.PR_counter = 0
		return true
	else
		-- Increasing the chance for next check
		self.PR_counter = self.PR_counter + actual_percentage
		return false
	end
end
