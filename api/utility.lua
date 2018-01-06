-- TODO dofile defaults.lua?
-- TODO verify_guide(definition)
--[[
-- OLD CODE.. make it NOICE

do -- Check definition.name
  if
    definition.name == nil or
    type(definition.name) ~= 'string' or
    definition.name == ''
  then
    return nil
  end
end

do -- Check definition.display
  if
    definition.display == nil or
    type(definition.display) ~= 'string' or
    definition.display == ''
  then
    return nil
  end
end

do -- Check definition.section_groups
  if -- section_groups
    definition.section_groups == nil or
    type(definition.section_groups) ~= 'table' or
    #definition.section_groups < 1
  then
    return nil
  end

  local section_lookups = {}
  for _, group in ipairs(definition.section_groups) do
    for _, section in ipairs(group) do
      -- check that section has valid parameters
      if
        section.name == nil or
        section.icon == nil or
        section.index == nil or
        section.page_groups == nil
      then
        return nil
      end

      -- TODO finish verification code
    end
  end
end
]]
