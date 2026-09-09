# Littérat'IA data collection platform

This platform allows for the collection of learner conversation and feedback data in the context of AI-assisted language learning.

It is meant to be used in conjunction with [an adaptation of this platform](https://gitlab.univ-lorraine.fr/labos/loria/mosaik/litteratia/litteratia-profs) for teacher feedback collection as well as a [framework](https://github.com/mi-1000/LitteratIA_Evaluation) suited to structure and evaluate this collected data.

> [!NOTE]
> This platform was forked from [`compar:IA`](https://github.com/betagouv/ComparIA) [`(Termignon, 2026)`](https://doi.org/10.48550/arXiv.2602.06669).

## Getting started

The platform is fully open source and self-hostable. The quickest way to get running:

```bash
cp .env.example .env       # Configure environment
make install               # Install all dependencies
make dev                   # Start backend + frontend
```

For the full setup guide (Docker, manual setup, testing, database, models, i18n, architecture), see **[`CONTRIBUTING.md`](CONTRIBUTING.md)**.

## How to use

- You can access the platform at [http://localhost:5173](http://localhost:5173) (or the configured host/port).
- You can host the platform on your own server to collect data from learners.
  - You can set the model list at [`utils/models/models.json`](utils/models/models.json) to configure the models available for learners. An example configuration is provided in [`utils/models/models.example.json`](utils/models/models.example.json).
  - You can tweak the dimensions collected by editing the [`litteratia_schema.sql`](litteratia_schema.sql) file. Propagate the changes into the backend ([`backend/arena/models.py`](backend/arena/models.py), [`backend/arena/persistence.py`](backend/arena/persistence.py)) and frontend ([`frontend/src/lib/chatService.svelte.ts`](frontend/src/lib/chatService.svelte.ts), [`frontend/src/routes/arene/components/LikePanel.svelte`](frontend/src/routes/arene/components/LikePanel.svelte)).
- Collected data includes learner conversations, feedback, and metadata. It can be saved as a CSV dump (_e.g._, using [PgAdmin](https://www.pgadmin.org)) for further analysis with the provided [evaluation framework](https://github.com/mi-1000/LitteratIA_Evaluation).