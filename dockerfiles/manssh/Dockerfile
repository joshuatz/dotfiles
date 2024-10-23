# https://hub.docker.com/layers/wendellsun/manssh/latest/images/sha256-c54cb45ef9c8dd0c01da853d1163b34ea77572c05809eee34e4a91af406413e7
FROM wendellsun/manssh@sha256:c54cb45ef9c8dd0c01da853d1163b34ea77572c05809eee34e4a91af406413e7

# Missing glibc stuff, since the base is alpine
# https://github.com/xwjdsh/manssh/blob/a7b987ecdbf187a1b6c02af7018482bdce0ef8be/Dockerfile
RUN apk add --no-cache gcompat
