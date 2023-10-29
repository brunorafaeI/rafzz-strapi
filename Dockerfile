# Creating multi-stage build for production
FROM node:20-bullseye as strapi_build

ARG NODE_ENV=production
ENV NODE_ENV=${NODE_ENV}

WORKDIR /opt/

RUN apt-get update && apt-get install -y build-essential \
  gcc \
  autoconf \
  automake \
  zlib1g-dev \
  libpng-dev \
  python3 \
  libvips-dev \
  git

COPY package.json package-lock.json ./
RUN npm install -g npm@latest node-gyp

RUN npm config set fetch-retry-maxtimeout 600000 -g
RUN npm ci --only=production

ENV PATH /opt/node_modules/.bin:$PATH

WORKDIR /opt/app

COPY . .

RUN npm run build

# Creating final production image
FROM strapi_build as strapi_backend

WORKDIR /opt

COPY --from=strapi_build /opt/node_modules ./node_modules

WORKDIR /opt/app

COPY --from=strapi_build /opt/app ./

ENV PATH /opt/node_modules/.bin:$PATH

RUN chown -R node:node /opt/app

USER node

EXPOSE 1338

CMD ["npm", "run", "start"]
