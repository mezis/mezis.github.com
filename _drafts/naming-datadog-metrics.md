# Naming Datadog metrics and tags

When pushing information to Datadog, you push to a _metric_ with
_tags_.

As an example, we could record failed background jobs this way:
  
    DATADOG.increment(
      'dj.failed_jobs',
      tags: [
        'host:worker5.housetrip.com',
        'env:production',
        'app:monorail'
      ]
    )

Conceptually, Datadog stores data for each (metric, tags) combination as a
separate time series.

A lot of Datadog's power is that it lets you perform various segmentations or
aggregations on a metric based on tags, for instance:

- sum of all metrics for a given tag (e.g. `dj.failed_jobs` for `production`)
- plot a metric separately for all tag values (e.g. plot failed jobs per host)

and so on.

This is important to naming, as if you discriminate between hosts or
environemnts (in the example above), you can't easily plot and aggregate
anymore.

## *Rule #1:* metric names are as generic as possible

Metric names relate to the domain & subsystem, and should never contain parts specific to a specific application, host, environment, or other runtime/deployment characteristic.

Good:

    job_queue.size env:production queue:week backend:dj
    http.response_time app:property_search env:production

Bad:
  
    dj.production.queue_size.week
    property_search.response_time env:produciton


## *Rule #2:* Tags should be uniformly used accross apps/services.

Tags are key-value pairs, colon-separated (the colon separator is required for Datadog to be able to segment).

The standard tags are:

- `env` for the environment - `production`, `staging`, etc (*mandatory*)
- `app` for the application - `monorail`, `routemaster`, etc (recommended)
- `host` for the current machine (EC2 only)
- `queue` for any named queue.

If you introduce a new tag that could be reused across services, or a metric
that is generic, please mention it here.
