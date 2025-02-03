const koa = require('koa');
const app = module.exports = new koa();
const server = require('http').createServer(app.callback());
const WebSocket = require('ws');
const wss = new WebSocket.Server({ server });
const Router = require('koa-router');
const cors = require('@koa/cors');
const bodyParser = require('koa-bodyparser');

app.use(bodyParser());
app.use(cors());
app.use(middleware);

function middleware(ctx, next) {
  const start = new Date();
  return next().then(() => {
    const ms = new Date() - start;
    console.log(`${start.toLocaleTimeString()} ${ctx.response.status} ${ctx.request.method} ${ctx.request.url} - ${ms}ms`);
  });
}

const transactions = [
  { id: 1, date: '2025-01-15', name: 'Groceries' },
  { id: 3, date: '2025-01-17', name: 'Entertainment'},
  { id: 4, date: '2025-01-18', name: 'Rent'},
];

const router = new Router();

router.get('/transactions', ctx => {
  ctx.response.body = transactions;
  ctx.response.status = 200;
});

router.get('/transaction/:id', ctx => {
  const { id } = ctx.params;
  const transaction = transactions.find(t => t.id == id);
  if (transaction) {
    ctx.response.body = transaction;
    ctx.response.status = 200;
  } else {
    ctx.response.body = { error: `Transaction with id ${id} not found` };
    ctx.response.status = 404;
  }
});

router.post('/transaction', ctx => {
  const { date, name } = ctx.request.body;

  if (date && name) {
    const id = transactions.length > 0 ? Math.max(...transactions.map(t => t.id)) + 1 : 1;
    const newTransaction = { id, date, name };
    transactions.push(newTransaction);

    broadcast(newTransaction);
    ctx.response.body = newTransaction;
    ctx.response.status = 201;
  } else {
    ctx.response.body = { error: "Missing or invalid transaction details" };
    ctx.response.status = 400;
  }
});

router.del('/transaction/:id', ctx => {
  const { id } = ctx.params;
  const index = transactions.findIndex(t => t.id == id);
  if (index !== -1) {
    const removedTransaction = transactions.splice(index, 1)[0];
    ctx.response.body = removedTransaction;
    ctx.response.status = 200;
  } else {
    ctx.response.body = { error: `Transaction with id ${id} not found` };
    ctx.response.status = 404;
  }
});

router.get('/allTransactions', ctx => {
  ctx.response.body = transactions;
  ctx.response.status = 200;
});

const broadcast = (data) => {
  wss.clients.forEach((client) => {
    if (client.readyState === WebSocket.OPEN) {
      client.send(JSON.stringify(data));
    }
  });
};

router.put('/transaction/:id', async (ctx) => {
  console.log(`PUT /transaction/${ctx.params.id}`);
  const id = parseInt(ctx.params.id);
  const { name, date } = ctx.request.body;
  console.log('Update data:', ctx.request.body);
  

  try {
    console.log('Element updated with id:', id);
	const index = transactions.findIndex(t => t.id == id);
	transactions[index].name = name;

    ctx.body = { product_id: id };
  } catch (err) {
    console.error('Error updating component:', err.message);
    ctx.status = 500;
    ctx.body = { message: 'Error updating component' };
  }
});

app.use(router.routes());
app.use(router.allowedMethods());

const port = 2528;

server.listen(port, () => {
  console.log(`🚀 Server listening on ${port} ... 🚀`);
});
