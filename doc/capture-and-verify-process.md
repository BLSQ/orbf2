## Objective

We want an automated, reliable check to see if adjustments made to:

- hesabu
- hesabu-go
- orbf-rules_engine
- orbf2

Have an impact on previously made calculations.

In order to do this we've identified several projects and org units that we want to check by using production data and comparing the results to a newer version.

## How to run?

Capturing can be done by running:

      DB_NAME=<production-copy> bundle exec rake data_test:capture_and_upload

Verifying can be run (and is run by CI) with:

      bundle exec rake spec:data_test

## High level overview

- Capture phase
- Verify phase

### Capture Phase

Take a snapshot of current production data, load it locally and execute a command to capture all the data needed to generate an invoice. The end goal is to have a set of data that:

- Works independently of DHIS2 availability
- Works without access to production database

This will run with the code as it was last deployed in production, these results should be captured but should never be committed to the repository (since they might contain sensitive production data).

### Verify Phase

With new code, like in a feature-branch, load a simulation with the data of the capture phase and compare the results against the results of the capture phase. This should work without access to DHIS2 or access to the production database.

## How to store capture phase data?

Since capture phase data should be treated as sensitive data, it should never be committed to the repo. Instead the results of the capure phase should be uploaded to a protected S3 bucket. The verify phase could use env variables to be able to download the results and then run against those files.

Currently these artefacts are generated:

Data to inflate to a known situation:

- `<name>-<orgunit>-data-compound.yml` (a YAML serialization of `DataCompound`)
- `<name>-<orgunit>-project.yml` (a YAML serialization of a `Project`)
- `<name>-<orgunit>-pyramid.yml` (a YAML serialization of the complete pyramid)
- `<name>-<orgunit>-input-values.json` (a JSON containing all DHIS2-input values)

Results:

- `<name>-<orgunit>-problem.json` (a JSON containing the problem that will be sent to hesabu)
- `<name>-<orgunit>-solution.json` (a JSON containing the solution coming out of hesabu)
- `<name>-<orgunit>-exported_values.json` (a JSON containing all values that would be exported)

Things we are looking for:

- Data should be versioned (S3 bucket is versioned)
- Data should be protected (S3 credentials are needed)
- Data should be retrievable (S3 credentials available on CI, read only!)
