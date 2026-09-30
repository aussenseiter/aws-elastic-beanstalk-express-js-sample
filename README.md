# AWS Elastic Beanstalk Node.js Sample App

This repository contains a sample Node.js web application built using [Express](https://expressjs.com/), meant to be used as part of the AWS DevOps Learning Path.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

## CI/CD

This fork is built and published by a Jenkins pipeline (`Jenkinsfile`) as part of ISEC6000 Secure DevOps Assessment 2.

- **Where it runs:** Jenkins job `23591561_Assessment2_pipeline`, which polls the `main` branch for changes every 5 minutes (a webhook isn't possible because Jenkins runs on localhost).
- **Pipeline stages:** Checkout → Install Dependencies → Unit Tests → Dependency Scan → Build Docker Image → Push to Docker Hub. Node stages run in a `node:16` agent.
- **Security gate:** `npm audit --audit-level=high` fails the pipeline on any High or Critical finding, before an image is built. The full JSON report is archived on every build.
- **Dependency override:** `serialize-javascript` is pinned to 7.0.7 via npm `overrides`. The version pulled in by Mocha 10 had High-severity advisories, and upgrading Mocha itself would drop Node 16 support.
- **Image location:** [`aldenjunus/isec6000-a2-app`](https://hub.docker.com/r/aldenjunus/isec6000-a2-app), tagged with the build number and short commit SHA.

### Running tests locally

Using the same Node 16 image as the pipeline:

```bash
docker run --rm --user node -v "$PWD":/app -w /app node:16 sh -c "npm ci && npm test"
```
