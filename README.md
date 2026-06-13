# opentofu-incus

Using opentofu to provision incus resources...

## Authenticating to Incus and using the API

Incus provides two apis. A local unix socket and a rest https endpoint.
The unix socket exists by default and does not need any authentiocation.
If using the unix socket the users group will decide what he can access.
The `incus-admin` group gives him full access. Users in the `incus` group
can be restricted to certain resources only.

The rest api has to be enabled and requires clients to authenticate either
using tls client certificates or OpenID Connect. There are also different
ways to restrict what authenticated users of the https api can do in incus.
See docs.

```bash
# Enable https api endpoint in incus config
config:
  core.https_address: '[::]:8443'
```

### Client trust token (via cli)

The goal is to have terraform be able to access the incus server.

[From their docs:](https://github.com/lxc/terraform-provider-incus/blob/main/docs/index.md)
> It makes use of the Incus client library, which currently looks in
> ~/.config/incus for client.crt and client.key files to authenticate against the Incus daemon.

There are other ways to do this but i have used the `incus` cli command
to generate the access credentials.

```bash
# Add a trust token for a specific client on the server:
incus config trust add CLIENTNAME
```

This will return a token that the client will need to use to add this
server as a remote.

```bash
# Add that server as a remote using the generated token
incus remote add REMOTE TOKEN
```

This will generate credentials for the client and add the server as a remote.
the incus cli then will be able to use it.

```bash
# List remotes
incus remote ls

# Switch (use) a specific remote
incus remote switch REMOTE

# Issue incus commands as usual
incus ls
```

Once this is set up and your local incus cli can access the remote
the terraform provider will be able to do so as well.

### Client trust token (via terraform)

If you dont have an incus cli on the client you can use the terraform
provider to create the credentials instead.  See the example in `incus-provider-token/`.

It configured the incus provide to accept and  store the credentials
in `incus-provider-token/.incus/`. The rest of the config should be clear.
First use init to get the provider. Then apply and provide the one time
token received from the server as a cli variable.


```bash
cd incus-provider-token/
tofu init
# Apply once with the token to receive and store credentials from server
tofu apply -var="incus_token=XXX"
```




