import EctoEnum

defenum(ApiStates, enabled: 0, deleted: 1)
defenum(ApiKinds, builtin: 0, custom: 1)

## TODO exit
defenum(ErrorKinds, error: 0)

defenum(ErrorTypes,
  unknown: 0,
  apply_middleware: 1,
  update_api: 2,
  build_request: 3,
  build_url: 4,
  load_api: 20
)

defenum(RequestMethods, get: 0, post: 1, put: 2, head: 3)
defenum(RequestStates, init: 0, ok: 1, failed: 2, error: 3, fatal: 4, paused: 10)
defenum(RequestContentTypes, none: 0, html: 1, json: 2, image: 3, binary: 4, text: 5, other: 10)
