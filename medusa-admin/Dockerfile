FROM node:17.1.0

WORKDIR /app

COPY package.json package-lock.json ./

COPY . .

RUN npm install

RUN npm run build

EXPOSE 3000

CMD ["npm", "run", "preview"]