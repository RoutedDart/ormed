import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import Layout from '@theme/Layout';
import Heading from '@theme/Heading';

import styles from './index.module.css';

const drivers = [
  {name: 'SQLite', packageName: 'ormed_sqlite', detail: 'local + tests', slug: 'sqlite'},
  {name: 'PostgreSQL', packageName: 'ormed_postgres', detail: 'production SQL', slug: 'postgres'},
  {name: 'MySQL', packageName: 'ormed_mysql', detail: 'MySQL + MariaDB', slug: 'mysql'},
  {name: 'D1', packageName: 'ormed_d1', detail: 'edge SQLite', slug: 'd1'},
  {name: 'Drift', packageName: 'ormed_drift', detail: 'shared executor', slug: 'drift'},
];

function Hero() {
  return (
    <header className={styles.hero}>
      <div className={styles.heroGrid} aria-hidden="true" />
      <div className={`container ${styles.heroInner}`}>
        <div className={styles.heroCopy}>
          <p className={styles.eyebrow}>DATABASE ACCESS FOR DART</p>
          <Heading as="h1">
            Start with the database.
            <span className={styles.heroAccent}> Add types when your domain is ready.</span>
          </Heading>
          <p className={styles.heroLead}>
            Ormed lets Dart apps connect, query, and migrate without ceremony.
            Begin with direct access, then add generated models, repositories,
            and typed queries as your application grows.
          </p>
          <div className={styles.heroActions}>
            <Link className={styles.primaryAction} to="/docs/getting-started/direct-database">
              Start direct <span aria-hidden="true">↗</span>
            </Link>
            <Link className={styles.textAction} to="/docs/getting-started/quick-start">
              Use generated models <span aria-hidden="true">→</span>
            </Link>
          </div>
          <div className={styles.heroMeta}>
            <span>Dart 3.12+</span>
            <span>SQLite · PostgreSQL · MySQL · D1 · Drift</span>
            <span>MIT licensed</span>
          </div>
        </div>

        <div className={styles.codeWindow} aria-label="Direct database example">
          <div className={styles.codeWindowBar}>
            <span className={styles.windowDots} aria-hidden="true"><i /><i /><i /></span>
            <span>lib/database.dart</span>
            <span className={styles.windowStatus}>READY</span>
          </div>
          <pre><code><span className={styles.codeMuted}>final</span>{' db = '}<span className={styles.codeKeyword}>await</span>{' '}<span className={styles.codeType}>SqliteDatabase</span>.connect(<br />
{'  path: '}<span className={styles.codeString}>&apos;database/app.sqlite&apos;</span>,<br />
);<br /><br />
<span className={styles.codeKeyword}>final</span>{' users = '}<span className={styles.codeKeyword}>await</span>{' db'}<br />
{'    .table('}<span className={styles.codeString}>&apos;users&apos;</span>{')'}<br />
{'    .whereEquals('}<span className={styles.codeString}>&apos;active&apos;</span>{', '}<span className={styles.codeNumber}>true</span>{')'}<br />
{'    .get();'}</code></pre>
          <div className={styles.codeWindowFoot}>
            <span><b className={styles.pulse} /> works without generated code</span>
            <span>rows returned</span>
          </div>
        </div>
      </div>
    </header>
  );
}

function StartPaths() {
  return (
    <section className={styles.paths}>
      <div className="container">
        <div className={styles.sectionIntro}>
          <p className={styles.eyebrow}>START WHERE YOU ARE</p>
          <Heading as="h2">Start simply. Grow without changing your habits.</Heading>
          <p>Choose the smallest useful path, then keep the same runtime and query habits as your app grows.</p>
        </div>
        <div className={styles.pathGrid}>
          <Link className={`${styles.pathCard} ${styles.pathCardFeatured}`} to="/docs/getting-started/direct-database">
            <span className={styles.cardIndex}>01</span>
            <h3>Use the database directly</h3>
            <p>Connect to SQLite, PostgreSQL, MySQL, or D1. Run SQL, schema plans, migrations, transactions, and table queries without a generated registry. Already using Drift? Share its executor with Ormed.</p>
            <span className={styles.cardLink}>Start direct <span aria-hidden="true">↗</span></span>
          </Link>
          <Link className={styles.pathCard} to="/docs/getting-started/quick-start">
            <span className={styles.cardIndex}>02</span>
            <h3>Generate your domain model</h3>
            <p>When your domain settles, annotate models and generate definitions, DTOs, repositories, relations, and typed query helpers.</p>
            <span className={styles.cardLink}>Follow Quick Start <span aria-hidden="true">↗</span></span>
          </Link>
          <Link className={styles.pathCard} to="/docs/guides/observability">
            <span className={styles.cardIndex}>03</span>
            <h3>Make database work visible</h3>
            <p>Add ordered interceptors and OpenTelemetry across queries, mutations, raw SQL, migrations, streams, and transactions.</p>
            <span className={styles.cardLink}>See observability <span aria-hidden="true">↗</span></span>
          </Link>
        </div>
      </div>
    </section>
  );
}

function CapabilityRail() {
  return (
    <section className={styles.capabilities}>
      <div className="container">
        <div className={styles.capabilityHeader}>
          <p className={styles.eyebrow}>WHY ORMED</p>
          <p>Keep the database visible. Use generated code where it removes repetition.</p>
        </div>
        <div className={styles.capabilityGrid}>
          <div><span className={styles.capabilityGlyph}>⌘</span><h3>Typed where it helps</h3><p>Generated models, repositories, relations, and codecs give domain code useful contracts without hiding the database.</p></div>
          <div><span className={styles.capabilityGlyph}>⌁</span><h3>Direct when it matters</h3><p>Use table queries, raw SQL, schema plans, and transactions when a model would add ceremony.</p></div>
          <div><span className={styles.capabilityGlyph}>◎</span><h3>Traceable in production</h3><p>Structured events and ordered interceptors make database behavior visible in logs and traces.</p></div>
        </div>
      </div>
    </section>
  );
}

function DriverStrip() {
  return (
    <section className={styles.drivers}>
      <div className="container">
        <div className={styles.driverIntro}>
          <p className={styles.eyebrow}>SUPPORTED BACKENDS + INTEGRATIONS</p>
          <Heading as="h2">One API across the databases and runtimes you already use.</Heading>
        </div>
        <div className={styles.driverGrid}>
          {drivers.map((driver, index) => (
            <Link className={styles.driverCard} to={`/docs/drivers/${driver.slug}`} key={driver.packageName}>
              <span className={styles.driverNumber}>0{index + 1}</span>
              <span><strong>{driver.name}</strong><small>{driver.packageName} · {driver.detail}</small></span>
              <span className={styles.driverArrow} aria-hidden="true">↗</span>
            </Link>
          ))}
        </div>
      </div>
    </section>
  );
}

export default function Home(): ReactNode {
  return (
    <Layout title="Database access for Dart" description="Start with direct database access, then add generated models, repositories, and typed queries when your domain needs them.">
      <Hero />
      <main>
        <StartPaths />
        <CapabilityRail />
        <DriverStrip />
        <section className={styles.finalCallout}>
          <div className="container">
            <div>
              <p className={styles.eyebrow}>READY TO START</p>
              <Heading as="h2">Begin with one connection. Grow from there.</Heading>
            </div>
            <Link className={styles.darkAction} to="/docs/">Choose your path <span aria-hidden="true">→</span></Link>
          </div>
        </section>
      </main>
    </Layout>
  );
}
