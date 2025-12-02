defmodule Shard.Social.PartyTest do
  use Shard.DataCase

  alias Shard.Social
  alias Shard.Social.{Party, PartyMember, PartyInvitation}
  alias Shard.UsersFixtures

  describe "changeset/2" do
    setup do
      user = UsersFixtures.user_fixture()
      %{user: user}
    end

    test "valid changeset with required fields", %{user: user} do
      attrs = %{leader_id: user.id}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
    end

    test "valid changeset with all fields", %{user: user} do
      attrs = %{
        name: "Test Party",
        leader_id: user.id,
        max_size: 4
      }
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      assert changeset.changes.name == "Test Party"
      assert changeset.changes.leader_id == user.id
      assert changeset.changes.max_size == 4
    end

    test "invalid changeset without leader_id" do
      attrs = %{name: "Test Party"}
      changeset = Party.changeset(%Party{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).leader_id
    end

    test "invalid changeset with max_size of 0" do
      user = UsersFixtures.user_fixture()
      attrs = %{leader_id: user.id, max_size: 0}
      changeset = Party.changeset(%Party{}, attrs)
      refute changeset.valid?
      assert "must be greater than 0" in errors_on(changeset).max_size
    end

    test "invalid changeset with max_size greater than 10" do
      user = UsersFixtures.user_fixture()
      attrs = %{leader_id: user.id, max_size: 11}
      changeset = Party.changeset(%Party{}, attrs)
      refute changeset.valid?
      assert "must be less than or equal to 10" in errors_on(changeset).max_size
    end

    test "valid changeset with max_size at boundary values" do
      user = UsersFixtures.user_fixture()
      
      # Test min boundary (1)
      attrs = %{leader_id: user.id, max_size: 1}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      
      # Test max boundary (10)
      attrs = %{leader_id: user.id, max_size: 10}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
    end

    test "changeset ignores unknown fields" do
      user = UsersFixtures.user_fixture()
      attrs = %{
        leader_id: user.id,
        unknown_field: "should be ignored"
      }
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      refute Map.has_key?(changeset.changes, :unknown_field)
    end

    test "changeset with default max_size" do
      user = UsersFixtures.user_fixture()
      attrs = %{leader_id: user.id}
      changeset = Party.changeset(%Party{}, attrs)
      assert changeset.valid?
      # Default max_size should be 6 according to schema
      party = %Party{}
      assert party.max_size == 6
    end
  end

  describe "schema" do
    test "has correct fields and types" do
      party = %Party{}
      assert Map.has_key?(party, :name)
      assert Map.has_key?(party, :max_size)
      assert Map.has_key?(party, :leader_id)
      assert party.max_size == 6  # default value
    end
  end

  describe "get_user_party/1" do
    test "returns nil when user is not in a party" do
      user = UsersFixtures.user_fixture()
      assert Social.get_user_party(user.id) == nil
    end

    test "returns party when user is in a party" do
      leader = UsersFixtures.user_fixture()
      {:ok, party} = Social.create_party(leader.id, %{name: "Test Party"})
      
      result = Social.get_user_party(leader.id)
      assert result.id == party.id
      assert result.name == "Test Party"
      assert result.leader_id == leader.id
      assert length(result.party_members) == 1
      assert hd(result.party_members).user_id == leader.id
    end
  end

  describe "create_party/2" do
    test "creates party with leader as member" do
      leader = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id, %{name: "Test Party"})
      
      assert party.name == "Test Party"
      assert party.leader_id == leader.id
      
      # Verify leader is added as member
      party_member = Repo.get_by(PartyMember, party_id: party.id, user_id: leader.id)
      assert party_member != nil
    end

    test "creates party with default attributes" do
      leader = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      assert party.leader_id == leader.id
      assert party.max_size == 6
    end
  end

  describe "leave_party/1" do
    test "returns error when user is not in a party" do
      user = UsersFixtures.user_fixture()
      assert Social.leave_party(user.id) == {:error, :not_in_party}
    end

    test "removes member from party" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      # Member leaves
      Social.leave_party(member.id)
      
      # Verify member is removed
      assert Repo.get_by(PartyMember, party_id: party.id, user_id: member.id) == nil
      # Verify party still exists
      assert Repo.get(Party, party.id) != nil
    end

    test "disbands party when leader leaves and no other members" do
      leader = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      Social.leave_party(leader.id)
      
      # Verify party is deleted
      assert Repo.get(Party, party.id) == nil
    end

    test "transfers leadership when leader leaves with other members" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      # Leader leaves
      Social.leave_party(leader.id)
      
      # Verify leadership transferred
      updated_party = Repo.get(Party, party.id)
      assert updated_party.leader_id == member.id
    end
  end

  describe "invite_to_party/2" do
    test "returns error when inviter is not in a party" do
      leader = UsersFixtures.user_fixture()
      friend = UsersFixtures.user_fixture()
      
      assert Social.invite_to_party(leader.id, friend.id) == {:error, :not_in_party}
    end

    test "returns error when inviter is not party leader" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      friend = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      assert Social.invite_to_party(member.id, friend.id) == {:error, :not_party_leader}
    end

    test "returns error when friend is already in a party" do
      leader = UsersFixtures.user_fixture()
      friend = UsersFixtures.user_fixture()
      
      {:ok, _party1} = Social.create_party(leader.id)
      {:ok, _party2} = Social.create_party(friend.id)
      
      assert Social.invite_to_party(leader.id, friend.id) == {:error, :friend_already_in_party}
    end

    test "creates party invitation successfully" do
      leader = UsersFixtures.user_fixture()
      friend = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      {:ok, invitation} = Social.invite_to_party(leader.id, friend.id)
      
      assert invitation.party_id == party.id
      assert invitation.inviter_id == leader.id
      assert invitation.invitee_id == friend.id
      assert invitation.status == "pending"
    end

    test "returns error when invitation already exists" do
      leader = UsersFixtures.user_fixture()
      friend = UsersFixtures.user_fixture()
      
      {:ok, _party} = Social.create_party(leader.id)
      
      # Send first invitation
      {:ok, _invitation} = Social.invite_to_party(leader.id, friend.id)
      
      # Try to send again
      assert Social.invite_to_party(leader.id, friend.id) == {:error, :invitation_already_sent}
    end

    test "reactivates previous declined invitation" do
      leader = UsersFixtures.user_fixture()
      friend = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Create a declined invitation
      %PartyInvitation{}
      |> PartyInvitation.changeset(%{
        party_id: party.id,
        inviter_id: leader.id,
        invitee_id: friend.id,
        status: "declined"
      })
      |> Repo.insert!()
      
      {:ok, invitation} = Social.invite_to_party(leader.id, friend.id)
      
      assert invitation.status == "pending"
      assert invitation.inviter_id == leader.id
    end
  end

  describe "disband_party/1" do
    test "returns error when user is not in a party" do
      user = UsersFixtures.user_fixture()
      assert Social.disband_party(user.id) == {:error, :not_in_party}
    end

    test "returns error when user is not party leader" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      assert Social.disband_party(member.id) == {:error, :not_party_leader}
    end

    test "disbands party successfully" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      {:ok, _} = Social.disband_party(leader.id)
      
      # Verify party and all members are deleted
      assert Repo.get(Party, party.id) == nil
      assert Repo.get_by(PartyMember, party_id: party.id) == nil
    end
  end

  describe "kick_from_party/2" do
    test "returns error when leader is not in a party" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      assert Social.kick_from_party(leader.id, member.id) == {:error, :not_in_party}
    end

    test "returns error when user is not party leader" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      assert Social.kick_from_party(member.id, leader.id) == {:error, :not_party_leader}
    end

    test "returns error when trying to kick self" do
      leader = UsersFixtures.user_fixture()
      
      {:ok, _party} = Social.create_party(leader.id)
      
      assert Social.kick_from_party(leader.id, leader.id) == {:error, :cannot_kick_self}
    end

    test "returns error when member is not in party" do
      leader = UsersFixtures.user_fixture()
      non_member = UsersFixtures.user_fixture()
      
      {:ok, _party} = Social.create_party(leader.id)
      
      assert Social.kick_from_party(leader.id, non_member.id) == {:error, :member_not_in_party}
    end

    test "kicks member successfully" do
      leader = UsersFixtures.user_fixture()
      member = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Add member to party
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party.id,
        user_id: member.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      {:ok, _} = Social.kick_from_party(leader.id, member.id)
      
      # Verify member is removed
      assert Repo.get_by(PartyMember, party_id: party.id, user_id: member.id) == nil
      # Verify party still exists
      assert Repo.get(Party, party.id) != nil
    end
  end

  describe "list_pending_party_invitations/1" do
    test "returns empty list when no invitations" do
      user = UsersFixtures.user_fixture()
      assert Social.list_pending_party_invitations(user.id) == []
    end

    test "returns pending invitations for user" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, _party} = Social.create_party(leader.id, %{name: "Test Party"})
      {:ok, _invitation} = Social.invite_to_party(leader.id, invitee.id)
      
      invitations = Social.list_pending_party_invitations(invitee.id)
      
      assert length(invitations) == 1
      invitation = hd(invitations)
      assert invitation.invitee_id == invitee.id
      assert invitation.status == "pending"
      assert invitation.party.name == "Test Party"
      assert invitation.inviter.id == leader.id
    end

    test "does not return declined invitations" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Create declined invitation
      %PartyInvitation{}
      |> PartyInvitation.changeset(%{
        party_id: party.id,
        inviter_id: leader.id,
        invitee_id: invitee.id,
        status: "declined"
      })
      |> Repo.insert!()
      
      assert Social.list_pending_party_invitations(invitee.id) == []
    end
  end

  describe "list_sent_party_invitations/1" do
    test "returns empty list when no invitations sent" do
      user = UsersFixtures.user_fixture()
      assert Social.list_sent_party_invitations(user.id) == []
    end

    test "returns sent invitations for user" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, _party} = Social.create_party(leader.id)
      {:ok, _invitation} = Social.invite_to_party(leader.id, invitee.id)
      
      invitations = Social.list_sent_party_invitations(leader.id)
      
      assert length(invitations) == 1
      invitation = hd(invitations)
      assert invitation.inviter_id == leader.id
      assert invitation.status == "pending"
      assert invitation.invitee.id == invitee.id
    end
  end

  describe "accept_party_invitation/1" do
    test "accepts invitation and adds user to party" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      {:ok, invitation} = Social.invite_to_party(leader.id, invitee.id)
      
      {:ok, _} = Social.accept_party_invitation(invitation.id)
      
      # Verify invitation is accepted
      updated_invitation = Repo.get(PartyInvitation, invitation.id)
      assert updated_invitation.status == "accepted"
      
      # Verify user is added to party
      party_member = Repo.get_by(PartyMember, party_id: party.id, user_id: invitee.id)
      assert party_member != nil
    end

    test "returns error when user is already in a party" do
      leader1 = UsersFixtures.user_fixture()
      leader2 = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, party1} = Social.create_party(leader1.id)
      {:ok, party2} = Social.create_party(leader2.id)
      
      # Add invitee to party2
      %PartyMember{}
      |> PartyMember.changeset(%{
        party_id: party2.id,
        user_id: invitee.id,
        joined_at: DateTime.utc_now()
      })
      |> Repo.insert!()
      
      # Create invitation manually since invite_to_party would fail due to friend already being in party
      invitation = %PartyInvitation{}
      |> PartyInvitation.changeset(%{
        party_id: party1.id,
        inviter_id: leader1.id,
        invitee_id: invitee.id,
        status: "pending"
      })
      |> Repo.insert!()
      
      assert Social.accept_party_invitation(invitation.id) == {:error, :already_in_party}
    end

    test "deletes other pending invitations when accepting" do
      leader1 = UsersFixtures.user_fixture()
      leader2 = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, _party1} = Social.create_party(leader1.id)
      {:ok, _party2} = Social.create_party(leader2.id)
      
      {:ok, invitation1} = Social.invite_to_party(leader1.id, invitee.id)
      {:ok, invitation2} = Social.invite_to_party(leader2.id, invitee.id)
      
      {:ok, _} = Social.accept_party_invitation(invitation1.id)
      
      # Verify other pending invitation is deleted
      assert Repo.get(PartyInvitation, invitation2.id) == nil
    end
  end

  describe "decline_party_invitation/1" do
    test "declines invitation" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, _party} = Social.create_party(leader.id)
      {:ok, invitation} = Social.invite_to_party(leader.id, invitee.id)
      
      {:ok, updated_invitation} = Social.decline_party_invitation(invitation.id)
      
      assert updated_invitation.status == "declined"
    end
  end

  describe "delete_declined_party_invitation/2" do
    test "deletes declined invitation" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Create declined invitation
      invitation = %PartyInvitation{}
      |> PartyInvitation.changeset(%{
        party_id: party.id,
        inviter_id: leader.id,
        invitee_id: invitee.id,
        status: "declined"
      })
      |> Repo.insert!()
      
      {count, _} = Social.delete_declined_party_invitation(party.id, invitee.id)
      
      assert count == 1
      assert Repo.get(PartyInvitation, invitation.id) == nil
    end

    test "deletes accepted invitation" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      
      # Create accepted invitation
      invitation = %PartyInvitation{}
      |> PartyInvitation.changeset(%{
        party_id: party.id,
        inviter_id: leader.id,
        invitee_id: invitee.id,
        status: "accepted"
      })
      |> Repo.insert!()
      
      {count, _} = Social.delete_declined_party_invitation(party.id, invitee.id)
      
      assert count == 1
      assert Repo.get(PartyInvitation, invitation.id) == nil
    end

    test "does not delete pending invitation" do
      leader = UsersFixtures.user_fixture()
      invitee = UsersFixtures.user_fixture()
      
      {:ok, party} = Social.create_party(leader.id)
      {:ok, invitation} = Social.invite_to_party(leader.id, invitee.id)
      
      {count, _} = Social.delete_declined_party_invitation(party.id, invitee.id)
      
      assert count == 0
      assert Repo.get(PartyInvitation, invitation.id) != nil
    end
  end
end
