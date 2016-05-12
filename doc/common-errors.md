# Errors

A list of some of the errors you might run into when developing on Smart Answers locally.


## "NoMethodError" when visiting the root URL

You'll see this error if you visit the root URL of the Smart Answers app (e.g. http://localhost:3000 or http://smartanswers.dev.gov.uk/). This is because we don't have anything configured to respond at this path.

### Exception

```
NoMethodError at /
undefined method `to_html' for nil:NilClass
```

### Resolution

Visit a specific Smart Answer, e.g. /marriage-abroad.


## "SocketError" when viewing a Smart Answer (relating to Content API)

__NOTE.__ This is specifically when the exception is raised in `SmartAnswerPresenter#artefact`.

You'll see this error if the Smart Answers app can't connect to the Content API.

### Exception

```
SocketError at /marriage-abroad
Failed to open TCP connection to contentapi.dev.gov.uk:80 (getaddrinfo: nodename nor servname provided, or not known)
```

### Resolution

There are a couple of solutions to this problem:

1. Set the `PLEK_SERVICE_CONTENTAPI_URI` environment variable to a valid host. NOTE. This doesn't need to be hosting the Content API (although you can use "https://www.gov.uk/api" if that's what you want), it simply needs to be a host that responds to HTTP requests.

2. Configure a web server (e.g. Apache) on your machine to respond to http://contentapi.dev.gov.uk. This is the default location of the Content API in development so configuring this means that you won't have to set the `PLEK_SERVICE_CONTENTAPI_URI` environment variable.


## "SocketError" when viewing a Smart Answer (relating to Worldwide API)

__NOTE.__ This is specifically when the exception is raised in methods like `WorldLocation#find`, `WorldLocation.all` or `WorldwideOrganisation.for_location` which try to access the Worldwide API.

You'll see this error if the Smart Answers app can't connect to the Worldwide API.

### Exception

```
SocketError at /marriage-abroad/y
Failed to open TCP connection to whitehall-admin.dev.gov.uk:80 (getaddrinfo: nodename nor servname provided, or not known)
```

### Resolution

There are a couple of solutions to this problem:

1. Set the `PLEK_SERVICE_WHITEHALL_ADMIN_URI` environment variable to "https://www.gov.uk".

2. Configure a web server (e.g. Apache) on your machine to respond to http://whitehall-admin.dev.gov.uk. This is the default location of the Worldwide API in development so configuring this means that you won't have to set the `PLEK_SERVICE_WHITEHALL_ADMIN_URI` environment variable.


## "Slimmer::CouldNotRetrieveTemplate" when viewing a Smart Answer

You'll see this error if the Smart Answers app can't connect to the [Static][static] host.

### Exception

```
Slimmer::CouldNotRetrieveTemplate at /marriage-abroad
Unable to fetch: 'wrapper' from 'http://static.dev.gov.uk/templates/wrapper.html.erb' because getaddrinfo: nodename nor servname provided, or not known
```

### Resolution

There are a couple of solutions to this problem:

1. Set the `PLEK_SERVICE_STATIC_URI` environment variable to "https://assets-origin.integration.publishing.service.gov.uk", which is the static/assets server running in integration.

2. Run the static/assets server locally at http://static.dev.gov.uk. This is the default location of the static/asset server in development so configuring this  means that you won't have to set the `PLEK_SERVICE_STATIC_URI` environment variable.

[static]: https://github.com/alphagov/static
