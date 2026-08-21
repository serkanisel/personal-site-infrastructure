# Personal Site Infrastructure

Docker Compose ile backend API, MVC frontend, PostgreSQL ve opsiyonel Flutter web ciktisini birlikte ayaga kaldirir.

```bash
docker compose up --build
```

Servisler:

- API: `http://localhost:8080`
- MVC frontend: `http://localhost:8081`
- PostgreSQL: `localhost:5432`
- Flutter web profili: `docker compose --profile mobile-web up --build`
