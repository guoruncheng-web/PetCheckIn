import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.container6}>
      <div className={styles.container4}>
        <div className={styles.container3}>
          <img src="../image/mhxchifj-o7mcfoe.svg" className={styles.icon} />
          <div className={styles.container2}>
            <div className={styles.container} />
          </div>
        </div>
        <div className={styles.heading1}>
          <p className={styles.text}>宠友</p>
        </div>
        <div className={styles.paragraph}>
          <p className={styles.text2}>记录爱宠的每一天</p>
        </div>
      </div>
      <div className={styles.card}>
        <div className={styles.cardHeader}>
          <div className={styles.cardTitle}>
            <p className={styles.text3}>登录</p>
          </div>
          <div className={styles.cardDescription}>
            <p className={styles.text2}>使用手机号登录您的账号</p>
          </div>
        </div>
        <div className={styles.cardContent}>
          <div className={styles.login}>
            <div className={styles.primitiveLabel}>
              <p className={styles.text4}>手机号</p>
            </div>
            <div className={styles.input}>
              <p className={styles.text5}>请输入手机号</p>
            </div>
          </div>
          <div className={styles.login2}>
            <div className={styles.primitiveLabel}>
              <p className={styles.text4}>验证码</p>
            </div>
            <div className={styles.container5}>
              <div className={styles.input2}>
                <p className={styles.text5}>请输入验证码</p>
              </div>
              <div className={styles.button}>
                <p className={styles.text6}>获取验证码</p>
              </div>
            </div>
          </div>
          <div className={styles.button2}>
            <p className={styles.text7}>登录</p>
          </div>
          <div className={styles.login3}>
            <div className={styles.paragraph2}>
              <p className={styles.text2}>还没有账号？</p>
            </div>
            <p className={styles.text8}>立即注册 →</p>
          </div>
        </div>
      </div>
      <div className={styles.paragraph3}>
        <p className={styles.text2}>登录即表示同意用户协议和隐私政策</p>
      </div>
    </div>
  );
}

export default Component;
