const request = require('supertest');
const app = require('../app');

describe('GET /', () => {
  it('"Hello World!" - it\'s 200 OK', async () => {
    await request(app)
      .get('/')
      .expect(200)
      .expect('Hello World!');
  });
});

describe('Unknown routes', () => {
  it('Not found - 404', async () => {
    await request(app)
      .get('/not-found')
      .expect(404)
  });
});
