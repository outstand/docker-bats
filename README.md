# BATS / Buildkite Plugin Tester [![Build status](https://badge.buildkite.com/500fdf41de3aedb37db15cc4d5acd6f47c8ae72ed6d1342a09.svg)](https://buildkite.com/outstand/docker-compose-buildkite-plugin)

A base docker image for testing [Buildkite plugins](https://buildkite.com/docs/agent/v3/plugins) with BATS. It includes:

* A non-root user/group at 1000:1000. A docker group is located at gid 900.
* Docker compose v2 and compose-switch for v1 support.
* [bats-core](https://github.com/bats-core/bats-core)
* [bats-support](https://github.com/bats-core/bats-support)
* [bats-assert](https://github.com/bats-core/bats-assert)
* [@lox](https://github.com/lox)'s fork of [bats-mock](https://github.com/lox/bats-mock)
* [bats-file](https://github.com/bats-core/bats-file)

Your plugin’s code is expected to be mounted to `/plugin`, and by default the image will run the command `bats tests/`.

## Usage

For example, say you had a plugin called `git-logger`, which took a `commit` option, and called `git log` via a command hook:

```yml
steps:
  - plugins:
      - foo/git-logger#v1.0.0:
          commit: "abc123"
```

To test this, you'd add the following `docker-compose.yml` file:

```yml
version: '3.4'
services:
  tests:
    image: buildkite/plugin-tester
    volumes:
      - ".:/plugin"
```

And you'd create the following test in `tests/command.bats`:

```bash
#!/usr/bin/env bats

load "$BATS_PATH/load.bash"

# Uncomment to enable stub debugging
# export GIT_STUB_DEBUG=/dev/tty

@test "calls git log" {
  export BUILDKITE_PLUGIN_GIT_LOGGER_COMMIT="abc123"

  stub git "log abc123 : echo git log output"

  run $PWD/hooks/command

  assert_output --partial "git log output"
  assert_success
  unstub git
}
```

Now you can run your tests locally:

```bash
docker compose run --rm tests
```

To set up it up in Buildkite, create a `.buildkite/pipeline.yml` file that uses the [docker-compose Buildkite Plugin](https://github.com/buildkite-plugins/docker-compose-buildkite-plugin) to run that same command on CI, for example:

```yml
steps:
  - plugins:
      - docker-compose#x.y.z:
          run: tests
```

## Developing

To test plugin-tester itself, use the following command:

```bash
docker compose run --rm tests
```

## License

MIT (see [LICENSE](LICENSE))
