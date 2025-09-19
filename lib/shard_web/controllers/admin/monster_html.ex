defmodule ShardWeb.Admin.MonsterHTML do
  use ShardWeb, :html
  import ShardWeb.CoreComponents

  embed_templates "monster_html/*"

  @doc """
  Renders a monster form.

  The form is defined in the template at
  monster_html/monster_form.html.heex
  """
  attr :changeset, Ecto.Changeset, required: true
  attr :action, :string, required: true
  attr :return_to, :string, default: nil

  def monster_form(assigns)
end
