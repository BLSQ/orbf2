## Objective

We want an automated, reliable check to see if adjustments made to:

- hesabu
- hesabu-go
- orbf-rules_engine
- orbf2

Have an impact on previously made calculations.

In order to do this we've identified several projects and org units that we want to check by using production data and comparing the results to a newer version.

## How to run?

There are two components, verifying and capturing. With verifying I mean using the artefacts from a capture phase as input files and comparing the results. Since the input files are set in time, we should always have the same results.

To gather the artefacts (we don't commit them), you'll need to set:

- FETCHER_S3_KEY
- FETCHER_S3_ACCESS

(Easiest is this to add them to config/application.yml)

You can now run `bundle exec rake spec:data_test`, which will download the artefacts and the run the verification against them. (If you add `KEEP_ARTEFACTS=1` it will not redownload the artefacts on each run).

## Capture phase

With capture phase, I mean running against a copy of production and take new snapshots and new results. Since verification runs against those we need to make sure we're using a valid set of data.

**Step 1**: `DB_NAME=<production-copy> bundle exec rake data_test:capture`

This will talk to DHIS2 and output new files into a `tmp/new_artefacts` directory.

**Step 2**: `bundle exec rake data_test:compare_capture`

This will compare all the files in the `spec/artefacts` and the `tmp/artefacts`

It will list both the input files and the result files.

If the input files changed, there's a high likelyhood that the result files will have been changed to (if they haven't, it's safe to use the new input files as the default).

If the result files have changed without the input files having changed, **pay attention** you'll now need to investigate whether this is caused by our code changing slightly or that the state of the system has caused this. When in doubt, don't overwrite the old files, they contain a state that we always want to support.

It's always safe to add new cases.

**Step 3**: Copy the files you want to change/add to `spec/artefacts`
**Step 4**: `bundle exec rake data_test:upload`

This will prompt you for confirmation about the previous steps, if you enter `y` it will zip the current state of the `spec/artefacts` directory and upload it to S3 and from then on will be used as the new artefacts.

For uploading you'll need the following keys set:

- ARCHIVAL_S3_ACCESS
- ARCHIVAL_S3_KEY

## Selective Capture

A full 'Capture Phase' will replace all known files with updated ones, there's a high chance of DHIS2 being changed slightly, or even the order of the rules in the project changing, which alters the serialized YAML.

Therefore if you have some small changes, I had a change which affected three test cases where it removed 10 lines from the solution and the problem, it's easier to do the following:

1. Download the artefacts: `bundle exec rake data_test:download`
2. Verify that you have small changes: `KEEP_ARTEFACTS=1 bundle exec rspec spec/lib/data_test.spec`
3. Generate new files `TEST_CASE=your,changed,cases,comma,separated be rake data_test:verify`
     Which will create new `solution.json`, `problem.json` and `exported_values.json` in `tmp/verifiers`, which you can then move to `spec/artefacts`.
4. Move new files to `spec/artefacts`
5. Spec should now pass: `KEEP_ARTEFACTS=1 bundle exec rspec spec/lib/data_test.spec`
6. Upload new artefacts: `bundle exec rake data_test:upload`

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
