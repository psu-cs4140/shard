defmodule Shard.Repo.Migrations.SeedBasicSkillTree do
  use Ecto.Migration

  def up do
    # Create Combat skill tree
    execute """
    INSERT INTO skill_trees (name, description, is_active, inserted_at, updated_at)
    VALUES ('Combat', 'Combat-focused skills for warriors and fighters', true, NOW(), NOW())
    """

    # Get the skill tree ID
    skill_tree_id_query = "SELECT id FROM skill_trees WHERE name = 'Combat'"

    # Create skill nodes
    execute """
    INSERT INTO skill_nodes (name, description, xp_cost, prerequisites, effects, position_x, position_y, skill_tree_id, inserted_at, updated_at)
    VALUES 
    ('Power Strike', 'Increases damage by 10%', 100, '{}', '{"damage_bonus": 0.1}', 1, 1, (#{skill_tree_id_query}), NOW(), NOW()),
    ('Toughness', 'Increases health by 20 points', 150, '{}', '{"health_bonus": 20}', 0, 2, (#{skill_tree_id_query}), NOW(), NOW()),
    ('Combat Veteran', 'Increases damage by 15% and health by 10', 300, ARRAY[(SELECT id FROM skill_nodes WHERE name = 'Power Strike')], '{"damage_bonus": 0.15, "health_bonus": 10}', 2, 2, (#{skill_tree_id_query}), NOW(), NOW()),
    ('Berserker Rage', 'Increases damage by 25% but reduces defense', 500, ARRAY[(SELECT id FROM skill_nodes WHERE name = 'Combat Veteran')], '{"damage_bonus": 0.25, "defense_penalty": 0.1}', 1, 3, (#{skill_tree_id_query}), NOW(), NOW()),
    ('Iron Will', 'Increases mana by 30 and resistance to debuffs', 400, ARRAY[(SELECT id FROM skill_nodes WHERE name = 'Toughness')], '{"mana_bonus": 30, "debuff_resistance": 0.2}', 0, 3, (#{skill_tree_id_query}), NOW(), NOW())
    """
  end

  def down do
    execute "DELETE FROM character_skills"
    execute "DELETE FROM skill_nodes"
    execute "DELETE FROM skill_trees WHERE name = 'Combat'"
  end
end
