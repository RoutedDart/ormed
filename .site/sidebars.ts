import type {SidebarsConfig} from '@docusaurus/plugin-content-docs';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const sidebars: SidebarsConfig = {
  docsSidebar: [
    'intro',
    {
      type: 'category',
      label: 'Getting Started',
      items: [
        'getting-started/installation',
        'getting-started/quick-start',
        'getting-started/configuration',
        'getting-started/code-generation',
      ],
    },
    {
      type: 'category',
      label: 'Models',
      items: [
        'models/defining-models',
        'models/relationships',
        'models/timestamps',
        'models/soft-deletes',
        'models/events',
        'models/model-methods',
        'models/factories',
      ],
    },
    {
      type: 'category',
      label: 'Queries',
      items: [
        'queries/query-builder',
        'queries/repository',
        'queries/relations',
        'queries/data-source',
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
    {
      type: 'category',
      label: 'Drivers',
      items: [
        'drivers/overview',
        'drivers/sqlite',
        'drivers/postgres',
        'drivers/mysql',
      ],
    },
    {
      type: 'category',
      label: 'CLI',
      items: [
        'cli/commands',
      ],
    },
    {
      type: 'category',
      label: 'Guides',
      items: [
        'guides/testing',
        'guides/best-practices',
        'guides/observability',
        'guides/multi-database',
        'guides/examples',
      ],
    },
    {
      type: 'category',
      label: 'Reference',
      items: [
        'reference/driver-capabilities',
      ],
    },
  ],
};

export default sidebars;
