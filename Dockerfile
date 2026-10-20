# concept-filter: JSON on stdin, admission JSON on stdout. Stateless; needs no
# network, volumes, or privileges. Exit 0 clean, 2 quarantine, 1 malformed.

# GHC 9.12.4 matches the hosted CI toolchain.
FROM haskell:9.12.4-slim-bookworm@sha256:e152e636354da35dcefc8037e00e68abd854d2df5f3a3d10fa8c2958fc50bad0 AS build
WORKDIR /src

# Dependencies first, so source edits reuse the cached layer.
COPY semantic-categorical-oracle.cabal cabal.project ./
RUN cabal update && cabal build --only-dependencies all

COPY src src
COPY cli cli
COPY app app
COPY test test
RUN cabal install exe:concept-filter --install-method=copy --installdir=/out \
 && strip /out/concept-filter

FROM debian:bookworm-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587
COPY --from=build /out/concept-filter /usr/local/bin/concept-filter
USER 65532:65532
ENTRYPOINT ["/usr/local/bin/concept-filter"]
