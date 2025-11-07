defmodule Shard.Repo.Migrations.AddUniqueConstraintToQuests do
  use Ecto.Migration

  def up do
    # First, remove duplicate quests keeping only the ones with the lowest ID
    execute """
    DELETE FROM quest_acceptances 
    WHERE quest_id IN (
      SELECT q2.id 
      FROM quests q1, quests q2 
      WHERE q1.title = q2.title 
      AND q1.giver_npc_id = q2.giver_npc_id 
      AND q1.id < q2.id
    )
    """

    execute """
    DELETE FROM quests 
    WHERE id IN (
      SELECT q2.id 
      FROM (SELECT * FROM quests) q1, (SELECT * FROM quests) q2 
      WHERE q1.title = q2.title 
      AND q1.giver_npc_id = q2.giver_npc_id 
      AND q1.id < q2.id
    )
    """

    # Add unique constraint on title + giver_npc_id combination
    create unique_index(:quests, [:title, :giver_npc_id], name: :quests_title_giver_npc_id_index)
  end

  def down do
    drop index(:quests, [:title, :giver_npc_id], name: :quests_title_giver_npc_id_index)
  end
end
