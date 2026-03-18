import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: '1. Start Here',
      items: [
        'getting-started/installation',
        'getting-started/quick-start',
        'getting-started/adopt-existing-project',
        'getting-started/configuration',
        'getting-started/code-generation',
      ],
    },
    {
      type: 'category',
      label: '2. Learn Ormed',
      items: [
        {
          type: 'category',
          label: 'Models',
          items: [
            'models/overview',
            'models/defining-models',
            'models/attributes',
            'models/casting',
            'models/relationships',
            'models/timestamps',
            'models/soft-deletes',
            'models/scopes',
            'models/model-methods',
            'models/factories',
            'models/events',
            'models/driver-overrides',
          ],
        },
        {
          type: 'category',
          label: 'Queries',
          items: [
            'queries/overview',
            'queries/query-builder',
            'queries/repository',
            'queries/relations',
            'queries/data-source',
            'queries/json',
            'queries/caching',
          ],
        },
        {
          type: 'category',
          label: 'Migrations',
          items: [
            'migrations/overview',
            'migrations/schema-builder',
            'migrations/running-migrations',
            'migrations/events',
            'migrations/squashing',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: '3. Database Drivers',
      items: [
        'drivers/overview',
        'drivers/sqlite',
        'drivers/postgres',
        'drivers/mysql',
        'drivers/d1',
        {
          type: 'category',
          label: 'Internals',
          items: [
            'drivers/internals/overview',
            'drivers/internals/plans',
            'drivers/internals/schema',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: '4. Build & Operate',
      items: [
        {
          type: 'category',
          label: 'Guides',
          items: [
            'guides/overview',
            {
              type: 'category',
              label: 'Fullstack',
              items: [
                'guides/fullstack/ormed-shelf-tutorial',
                'guides/fullstack/setup',
                'guides/fullstack/models',
                'guides/fullstack/migrations-seeds',
                'guides/fullstack/server-routes',
                'guides/fullstack/api',
                'guides/fullstack/templates-storage',
                'guides/fullstack/cli-runbook',
                'guides/fullstack/testing',
              ],
            },
            'guides/testing',
            'guides/multi-database',
            'guides/observability',
            'guides/date-time',
            'guides/best-practices',
            'guides/analyzer-plugin',
            'guides/examples',
          ],
        },
        {
          type: 'category',
          label: 'CLI',
          items: [
            'cli/overview',
            'cli/migrations',
            'cli/seeding',
            'cli/schema',
            'cli/commands',
          ],
        },
      ],
    },
    {
      type: 'category',
      label: '5. Reference',
      items: [
        'reference/code-examples',
        'reference/driver-capabilities',
      ],
    },
  ],
};

export default sidebars;
