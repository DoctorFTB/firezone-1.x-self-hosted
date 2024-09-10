# Based on https://github.com/firezone/firezone/blob/4ac447ad1f0c65db3660f4311ad7c1d9040fa0e1/elixir/apps/domain/priv/repo/seeds.exs

alias Domain.{Repo, Accounts, Auth, Actors, Relays, Gateways}

# Configurable variables

account_name = "REPLACE-ME Account"
# symbol "-" is not allowed!
account_slug = "REPLACE_ME"

admin_actor_name = "REPLACE-ME"
admin_actor_email = "REPLACE-ME@account.my"
admin_actor_password = "REPLACE-ME-MIN-12-SYMBOLS"

relay_group_name = "REPLACE-ME"
site_name = "REPLACE-ME"

# Inserts

{:ok, account} =
  Accounts.create_account(%{
    name: account_name,
    slug: account_slug
  })

account
|> Ecto.Changeset.change(
  features: %{
    flow_activities: true,
    policy_conditions: true,
    multi_site_resources: true,
    traffic_filters: true,
    self_hosted_relays: true,
    idp_sync: true,
    rest_api: true,
    internet_resource: true
  },
  limits: %{
    # The devil is here... Shh...
    users_count: 666,
    monthly_active_users_count: 666,
    service_accounts_count: 666,
    gateway_groups_count: 666,
    account_admin_users_count: 666
  }
)
|> Repo.update!()

{:ok, _everyone_group} =
  Domain.Actors.create_managed_group(account, %{
    name: "Everyone",
    membership_rules: [%{operator: true}]
  })

{:ok, userpass_provider} =
  Auth.create_provider(account, %{
    name: "UserPass",
    adapter: :userpass,
    adapter_config: %{}
  })

{:ok, admin_actor} =
  Actors.create_actor(account, %{
    type: :account_admin_user,
    name: admin_actor_name
  })

{:ok, admin_actor_userpass_identity} =
  Auth.create_identity(admin_actor, userpass_provider, %{
    provider_identifier: admin_actor_email,
    provider_virtual_state: %{
      "password" => admin_actor_password,
      "password_confirmation" => admin_actor_password
    }
  })

nonce = "n"

admin_actor_context = %Auth.Context{
  type: :browser,
  user_agent: "no-op",
  remote_ip: {127, 0, 0, 1}
}

token_expires_at = DateTime.utc_now() |> DateTime.add(10, :second)

{:ok, admin_actor_token} =
  Auth.create_token(admin_actor_userpass_identity, admin_actor_context, nonce, token_expires_at)

{:ok, admin_subject} =
  Auth.build_subject(admin_actor_token, admin_actor_context)

_relay_group =
  account
  |> Relays.Group.Changeset.create(%{name: relay_group_name}, admin_subject)
  |> Repo.insert!()

_gateway_group =
  account
  |> Gateways.Group.Changeset.create(
    %{name: site_name, tokens: [%{}]},
    admin_subject
  )
  |> Repo.insert!()
