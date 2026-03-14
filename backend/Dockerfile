FROM node:25 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production || npm install --production || exit 1
COPY . .

FROM node:25-alpine3.22
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./
COPY --from=builder /app/src ./src

RUN chown -R node:node /app && \
    chmod -R 755 /app
USER node

EXPOSE 5000
CMD ["npm", "start"]