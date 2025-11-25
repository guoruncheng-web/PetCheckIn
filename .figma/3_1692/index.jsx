import React from 'react';

import styles from './index.module.scss';

const Component = () => {
  return (
    <div className={styles.container6}>
      <div className={styles.container4}>
        <div className={styles.container3}>
          <img src="../image/mhxd4qo0-8cw02yy.svg" className={styles.icon} />
          <div className={styles.container2}>
            <div className={styles.container} />
          </div>
        </div>
        <div className={styles.heading1}>
          <p className={styles.text}>宠友</p>
        </div>
        <div className={styles.paragraph}>
          <p className={styles.text2}>加入宠友，分享爱宠时光</p>
        </div>
      </div>
      <div className={styles.card}>
        <div className={styles.cardHeader}>
          <div className={styles.register}>
            <div className={styles.button}>
              <img src="../image/mhxd4qo0-sf01p0s.svg" className={styles.icon2} />
            </div>
            <div className={styles.cardTitle}>
              <p className={styles.text3}>注册账号</p>
            </div>
          </div>
          <div className={styles.cardDescription}>
            <p className={styles.text2}>创建您的宠友账号</p>
          </div>
        </div>
        <div className={styles.cardContent}>
          <div className={styles.register2}>
            <div className={styles.primitiveLabel}>
              <p className={styles.text4}>手机号</p>
            </div>
            <div className={styles.input}>
              <p className={styles.text5}>请输入手机号</p>
            </div>
            <div className={styles.paragraph2}>
              <p className={styles.text2}>手机号将作为您的登录账号</p>
            </div>
          </div>
          <div className={styles.register3}>
            <div className={styles.primitiveLabel}>
              <p className={styles.text4}>验证码</p>
            </div>
            <div className={styles.container5}>
              <div className={styles.input2}>
                <p className={styles.text5}>请输入验证码</p>
              </div>
              <div className={styles.button2}>
                <p className={styles.text6}>获取验证码</p>
              </div>
            </div>
          </div>
          <div className={styles.button3}>
            <p className={styles.text7}>确认注册</p>
          </div>
          <div className={styles.register4}>
            <div className={styles.paragraph3}>
              <p className={styles.text2}>已有账号？</p>
            </div>
            <p className={styles.text8}>立即登录 →</p>
          </div>
        </div>
      </div>
      <div className={styles.paragraph4}>
        <p className={styles.text2}>注册即表示同意用户协议和隐私政策</p>
      </div>
    </div>
  );
}

export default Component;
