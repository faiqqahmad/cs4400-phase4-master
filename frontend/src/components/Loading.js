import React from 'react';
import styles from '@/styles/Loading.module.css';

const Loading = () => (
  <div className={styles.spinner}>
    <div className={styles.ldsDualRing} />
  </div>
);

export default Loading;