# vue滚动视图组件
## 介绍
基于[better-scroll.js库](https://better-scroll.gitee.io/docs/zh-CN/)封装的vue2.x滚动视图组件，用于展示上下滚动的页面，解决了ios手机页面快速滚动卡死的问题，同时扩展了下拉刷新和上拉加载的功能，预设了刷新和加载过程每个阶段的插槽，做到极高的定制化
## 注意事项
better-scroll文档解释了滚动原理：在滚动方向上，第一个子元素的长度超过了容器的长度时就可以滚动，当使用发现滚动不了时，请检查子元素的长度是否超过了容器的长度

<strong style="color: red; font-size: 18px">scroll-view组件内容元素在滚动方向上的长度必须大于容器元素，scroll-view的宽高设置为100%，所以父级元素要给定宽高</strong>

## 代码封装实现
```
<template>
    <div
        ref="wrapper"
        class="wrapper"
        :style="`--color: ${color};--size:${vwSize};`"
    >
        <div class="content">
            <!-- 下拉刷新 -->
            <div class="refresh-tips" v-if="openRefresh">
                <div v-show="pulling">
                    <slot name="pulling">
                        <div class="tips">{{ pullingText }}</div>
                    </slot>
                </div>
                <div v-show="loosing">
                    <slot name="loosing">
                        <div class="tips">{{ loosingText }}</div>
                    </slot>
                </div>
                <div v-show="refreshing">
                    <slot name="refreshing">
                        <div class="loading-wrapper">
                            <div class="loading"></div>
                            <div class="tips">{{ refreshingText }}</div>
                        </div>
                    </slot>
                </div>
                <div v-show="success">
                    <slot name="success">
                        <div class="tips">{{ successText }}</div>
                    </slot>
                </div>
            </div>
            <!-- 主体内容 -->
            <slot></slot>
            <!-- 上拉加载 -->
            <div class="load-tips" v-if="openLoad">
                <div v-show="finished">
                    <slot name="finished">
                        <div class="tips">{{ finishedText }}</div>
                    </slot>
                </div>
                <div v-show="!finished && !loading">
                    <slot name="loadingBefore">
                        <div class="tips">{{ loadingBeforeText }}</div>
                    </slot>
                </div>
                <div v-show="!finished && loading">
                    <slot name="loading">
                        <div class="loading-wrapper">
                            <div class="loading"></div>
                            <div class="tips">{{ refreshingText }}</div>
                        </div>
                    </slot>
                </div>
            </div>
        </div>
    </div>
</template>

<script>
import BScroll from "@better-scroll/core";
import ObserveDOM from "@better-scroll/observe-dom";
BScroll.use(ObserveDOM);
import Pullup from "@better-scroll/pull-up";
BScroll.use(Pullup);
import PullDown from "@better-scroll/pull-down";
BScroll.use(PullDown);

const defaultConfig = {
    probeType: 3,
    // 滚动到顶部或底部的回弹效果
    bounce: false,
    click: true,
    scrollX: false,
    scrollY: true,
    // 开启对 content 以及 content 子元素 DOM 改变的探测
    observeDOM: true,
};
export default {
    name: "ScrollView",
    props: {
        scrollConfig: {
            type: Object,
            default() {
                return {};
            },
        },
        // 提示文案的颜色
        color: {
            type: String,
            default: "#000",
        },
        // 提示文案的字体大小
        size: {
            type: Number | String,
            default: 28,
        },
        // 是否开启上拉加载
        openLoad: {
            type: Boolean,
            default: false,
        },
        // 是否处于加载状态
        loading: {
            type: Boolean,
            required: false,
        },
        // 是否已加载完成
        finished: {
            type: Boolean,
            required: false,
        },
        // 加载前的提示提示文案
        loadingBeforeText: {
            type: String,
            default: "上拉加载更多",
        },
        // 加载过程中的提示文案
        loadingText: {
            type: String,
            default: "加载中",
        },
        // 加载完成后的提示文案
        finishedText: {
            type: String,
            default: "没有更多了",
        },

        // 是否开启下拉刷新
        openRefresh: {
            type: Boolean | Object,
            default: false,
        },
        // 是否处于刷新状态
        refreshing: {
            type: Boolean,
            required: false,
        },
        // 下拉过程的提示文案
        pullingText: {
            type: String,
            default: "下拉刷新",
        },
        // 释放过程的提示文案
        loosingText: {
            type: String,
            default: "手指释放刷新",
        },
        // 刷新过程的提示文案
        refreshingText: {
            type: String,
            default: "刷新中...",
        },
        // 刷新成功的提示文案
        successText: {
            type: String,
            default: "刷新成功",
        },
        // 刷新成功提示展示时长(ms)
        successDuration: {
            type: Number,
            default: 0,
        },
    },
    data() {
        return {
            pulling: false,
            loosing: false,
            success: false,
        };
    },
    mounted() {
        setTimeout(() => {
            this.__initScroll();
            // 如果开启了上拉加载的功能，首次组件渲染完成就通知父组件去拉数据
            if (this.openLoad) {
                this.pullingUpHandler();
            }
        }, 20);
    },
    methods: {
        // 初始化滚动视图组件
        __initScroll() {
            if (!this.$refs["wrapper"]) {
                return;
            }

            // 合并初始化的配置项
            let config = {};
            if (this.openRefresh) {
                config.bounce = { top: true, bottom: false };
                config.pullDownRefresh = { threshold: 60, stop: 60 };
            }
            config.pullUpLoad = this.openLoad;

            config = Object.assign(
                {},
                defaultConfig,
                this.scrollConfig,
                config
            );
            // 初始化better-scroll
            this.scroll = new BScroll(this.$refs["wrapper"], config);

            this.scroll && this.addEvent();
        },
        addEvent() {
            // 派发初始化成功事件
            this.$emit("ready", this.scroll);

            // 派发滚动事件
            this.scroll.on("scroll", (pos) => {
                this.$emit("scroll", pos);
            });
            if (this.openLoad) {
                // 监听上拉加载事件
                this.scroll.on("pullingUp", this.pullingUpHandler);
            }
            if (this.openRefresh) {
                // 监听下拉刷新事件(3个阶段)
                this.scroll.on("enterThreshold", () => {
                    this.clearStatus();
                    this.pulling = true;
                });
                this.scroll.on("leaveThreshold", () => {
                    this.clearStatus();
                    this.loosing = true;
                });
                this.scroll.on("pullingDown", this.pullingDownHandler);
            }
        },
        // 处理上拉加载
        pullingUpHandler() {
            this.$emit("update:loading", true);
            this.$emit("load");
        },
        // 处理下拉刷新
        pullingDownHandler() {
            this.clearStatus();
            this.$emit("update:refreshing", true);
            this.$emit("refresh");
        },
        // 更新滚动视图组件
        refresh() {
            this.scroll && this.scroll.refresh();
        },
        // 滚动
        scrollToXY(x, y, time = 300) {
            this.scroll && this.scroll.scrollTo(x, y, time);
        },
        // 清除所有的状态
        clearStatus() {
            this.pulling = false;
            this.loosing = false;
            this.success = false;
        },
    },
    computed: {
        vwSize() {
            if (!isNaN(Number(this.size)) || this.size.indexOf("px") !== -1) {
                return `${parseFloat(this.size) / 7.5}vw`;
            } else {
                return this.size;
            }
        },
    },
    watch: {
        // 监听到loading结束就刷新
        loading(val) {
            if (!val) {
                this.$nextTick(() => {
                    this.refresh;
                    this.scroll.finishPullUp();
                });
            }
        },
        // 监听到refreshing结束就刷新
        refreshing(val) {
            if (!val) {
                if (this.successDuration < 20) {
                    this.clearStatus();
                    this.success = true;
                    this.$nextTick(this.scroll.finishPullDown);
                } else {
                    this.clearStatus();
                    this.success = true;
                    setTimeout(
                        this.scroll.finishPullDown,
                        this.successDuration
                    );
                }
            }
        },
        // 监听到加载完成后，关闭上拉加载
        finished(val) {
            if (val) {
                this.$nextTick(this.scroll.closePullUp);
            }
        },
    },
};
</script>

<style  scoped>
.wrapper {
    width: 100%;
    height: 100%;
    overflow: hidden;
}

.wrapper .refresh-tips {
    position: absolute;
    width: 100%;
    transform: translateY(-100%) translateZ(1px);
}

.wrapper .tips {
    padding: 34px 0;
    display: flex;
    justify-content: center;
    align-items: center;
    color: var(--color);
    font-size: var(--size);
}

.wrapper .loading-wrapper {
    width: 100%;
    display: flex;
    justify-content: center;
    align-items: center;
}

.wrapper .loading-wrapper .loading {
    box-sizing: border-box;
    width: calc(var(--size) * 1.2);
    height: calc(var(--size) * 1.2);
    border-width: 2px;
    border-style: solid;
    border-color: var(--color);
    border-top-color: transparent;
    border-radius: 100%;
    animation: circle infinite 0.75s linear;
}

.wrapper .loading-wrapper .tips {
    margin-left: 20px;
}

@keyframes circle {
    0% {
        transform: rotate(0);
    }
    100% {
        transform: rotate(360deg);
    }
}
</style>

```

## 代码演示
### 基础用法

```
<div class="test">
    <!-- 滚动区域 -->
    <scroll-view>
        <div class="cell" v-for="i in list" :key="i">{{ i }}</div>
    </scroll-view>
</div>
```
```js
export default {
    data() {
        return {
            list: [],
            loading: false,
            finished: false,
            refreshing: false,
        };
    },
    methods: {
        onLoad() {
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            setTimeout(() => {
                for (let i = 0; i < 30; i++) {
                    this.list.push(this.list.length + 1);
                }
            }, 1000);
        }
    },
    created() {
        this.onLoad();
    },
};
```
```css
.test {
    width: 100vw;
    height: 100vh;
    background: #fff;
}
.cell {
    height: 108px;
    font-size: 18px;
    border-bottom: 1px solid #ccc;
    line-height: 108px;
    text-align: center;
}
```
### 上拉加载
scroll-view组件通过loading和finished两个变量控制加载状态。当组件滚动到底部时，scroll-view组件会给父组件抛出load事件同时将父组件的loading设置为true，父组件监听load事件发起异步操作更新数据，数据更新完毕后，将loading设置为false即可。如果数据已经全部加载完了，就将finishe设置为true即可。
```
<div class="test">
    <!-- 滚动区域 -->
    <scroll-view
        :openLoad="true"
        :loading.sync="loading"
        :finished="finished"
        @load="onLoad"
    >
        <div class="cell" v-for="i in list" :key="i">{{ i }}</div>
    </scroll-view>
</div>
```
```js
export default {
    data() {
        return {
            list: [],
            loading: false,
            finished: false
        };
    },
    methods: {
        onLoad() {
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            setTimeout(() => {
                for (let i = 0; i < 10; i++) {
                    this.list.push(this.list.length + 1);
                }

                // 加载状态结束
                this.loading = false;

                // 数据全部加载完成
                if (this.list.length >= 30) {
                    this.finished = true;
                }
            }, 1000);
        },

    },
};
```
```css
.test {
    width: 100vw;
    height: 100vh;
    background: #fff;
}
.cell {
    height: 108px;
    font-size: 18px;
    border-bottom: 1px solid #ccc;
    line-height: 108px;
    text-align: center;
}
```
### 下拉刷新
scroll-view组件通过refreshing变量控制刷新状态。当组件滚动到顶部时继续下拉一段距离，scroll-view组件会给父组件抛出refresh事件同时将父组件的refreshing设置为true，父组件监听refresh事件进行操作，操作完毕后，将refreshing设置为false即可，表示刷新成功。
```
<div class="test">
    <!-- 滚动区域 -->
    <scroll-view
        :openRefresh="true"
        :refreshing.sync="refreshing"
        @refresh="onRefresh"
    >
        <div class="cell" v-for="i in list" :key="i">{{ i }}</div>
    </scroll-view>
</div>
```
```js
export default {
    data() {
        return {
            list: [],
            refreshing: false,
        };
    },
    methods: {
        onLoad() {
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            setTimeout(() => {
                if (this.refreshing) {
                    this.list = [];
                    this.refreshing = false;
                }
                for (let i = 0; i < 20; i++) {
                    this.list.push(this.list.length + 1);
                }
            }, 1000);
        },
        onRefresh() {
            this.onLoad();
        },
    },
    created() {
        this.onLoad();
    },
};
```
```css
.test {
    position: relative;
    width: 100%;
    height: 100%;
    background: #fff;
}
.cell {
    height: 108px;
    font-size: 18px;
    border-bottom: 1px solid #ccc;
    line-height: 108px;
    text-align: center;
}
```
### 上拉加载+下拉刷新
完整的组件功能
```
<div class="test">
    <!-- 滚动区域 -->
    <scroll-view
        :openLoad="true"
        :loading.sync="loading"
        :finished="finished"
        :openRefresh="true"
        :refreshing.sync="refreshing"
        @load="onLoad"
        @refresh="onRefresh"
    >
        <div class="cell" v-for="i in list" :key="i">{{ i }}</div>
    </scroll-view>
</div>
```
```js
export default {
    data() {
        return {
            list: [],
            loading: false,
            finished: false,
            refreshing: false,
        };
    },
    methods: {
        onLoad() {
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            setTimeout(() => {
                if (this.refreshing) {
                    this.list = [];
                    this.refreshing = false;
                }
                for (let i = 0; i < 10; i++) {
                    this.list.push(this.list.length + 1);
                }

                // 加载状态结束
                this.loading = false;

                // 数据全部加载完成
                if (this.list.length >= 30) {
                    this.finished = true;
                }
            }, 1000);
        },
        onRefresh() {
            // 重置加载完毕的状态
            this.finished = false;

            // 重新加载数据
            // 将 loading 设置为 true，表示处于加载状态
            this.loading = true;
            this.onLoad();
        },
    },
};
```
```css
.test {
    position: relative;
    width: 100%;
    height: 100%;
    background: #fff;
}
.cell {
    height: 108px;
    font-size: 18px;
    border-bottom: 1px solid #ccc;
    line-height: 108px;
    text-align: center;
}
```
### 自定义提示
srcoll-view组件提供了color和size两个props，使用者可以简单的定制提示内容的颜色和font-size，srcoll-view组件使用vw作为单位（以iphone6 750px为基准，使用者也应传入此基准设计稿的值），传入数字（20）或者字符串（20px）,内部会自动转成vw单位，传入的是rem或em则不转换
```
<div class="test">
    <!-- 滚动区域 -->
    <scroll-view
        :openLoad="true"
        :loading.sync="loading"
        :finished="finished"
        :openRefresh="true"
        :refreshing.sync="refreshing"
        color="skyblue"
        size="40px"
        @load="onLoad"
        @refresh="onRefresh"
    >
        <div class="cell" v-for="i in list" :key="i">{{ i }}</div>
    </scroll-view>
</div>
```
```js
export default {
    data() {
        return {
            list: [],
            loading: false,
            finished: false,
            refreshing: false,
        };
    },
    methods: {
        onLoad() {
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            setTimeout(() => {
                if (this.refreshing) {
                    this.list = [];
                    this.refreshing = false;
                }
                for (let i = 0; i < 10; i++) {
                    this.list.push(this.list.length + 1);
                }

                // 加载状态结束
                this.loading = false;

                // 数据全部加载完成
                if (this.list.length >= 30) {
                    this.finished = true;
                }
            }, 1000);
        },
        onRefresh() {
            // 清空列表数据
            this.finished = false;

            // 重新加载数据
            // 将 loading 设置为 true，表示处于加载状态
            this.loading = true;
            this.onLoad();
        },
    },
};
```
```css
.test {
    position: relative;
    width: 100%;
    height: 100%;
    background: #fff;
}
.cell {
    height: 108px;
    font-size: 18px;
    border-bottom: 1px solid #ccc;
    line-height: 108px;
    text-align: center;
}
```

srcoll-view组件预设了下拉刷新和上拉加载各阶段的插槽，使用者可以通过插槽自定义提示内容，具有极高的自由度
```
<div class="test">
    <!-- 滚动区域 -->
    <scroll-view
        :openLoad="true"
        :loading.sync="loading"
        :finished="finished"
        :openRefresh="true"
        :refreshing.sync="refreshing"
        @load="onLoad"
        @refresh="onRefresh"
    >
        <div slot="pulling" class="slot-tips">下拉刷新slot</div>
        <div slot="loosing" class="slot-tips">释放刷新slot</div>
        <div slot="refreshing" class="slot-tips">刷新中slot</div>
        <div slot="success" class="slot-tips">刷新成功slot</div>
        <div class="cell" v-for="i in list" :key="i">{{ i }}</div>
        <div slot="loading" class="slot-tips">加载中slot</div>
        <div slot="finished" class="slot-tips">加载完毕slot</div>
        <div slot="loadingBefore" class="slot-tips">上拉加载slot</div>
    </scroll-view>
</div>
```
```js
export default {
    data() {
        return {
            list: [],
            loading: false,
            finished: false,
            refreshing: false,
        };
    },
    methods: {
        onLoad() {
            // 异步更新数据
            // setTimeout 仅做示例，真实场景中一般为 ajax 请求
            setTimeout(() => {
                if (this.refreshing) {
                    this.list = [];
                    this.refreshing = false;
                }
                for (let i = 0; i < 10; i++) {
                    this.list.push(this.list.length + 1);
                }

                // 加载状态结束
                this.loading = false;

                // 数据全部加载完成
                if (this.list.length >= 30) {
                    this.finished = true;
                }
            }, 1000);
        },
        onRefresh() {
            // 清空列表数据
            this.finished = false;

            // 重新加载数据
            // 将 loading 设置为 true，表示处于加载状态
            this.loading = true;
            this.onLoad();
        },
    },
};
```
```css
.test {
    position: relative;
    width: 100%;
    height: 100%;
    background: #fff;
}
.cell {
    height: 108px;
    font-size: 18px;
    border-bottom: 1px solid #ccc;
    line-height: 108px;
    text-align: center;
}
.slot-tips {
    padding: 50px 0;
    text-align: center;
    color: red;
    font-size: 32px;
}
```
## API
### props
| 参数 | 说明 | 类型 | 默认值 |
| --- | --- | --- | --- |
|openLoad|是否开启上拉加载|Boolean|false
| loading | 是否处于加载状态（.sync） | Boolean | false |
| finished | 是否已加载完成 | Boolean | false |
| loadingBeforeText | 加载前的提示提示文案 | String | 上拉加载更多 |
| loadingText | 加载过程中的提示文案 | String | 加载中 |
|finishedText | 加载完成后的提示文案 | String | 没有更多了 |
| openRefresh | 是否开启下拉刷新 | Boolean或Object | false |
| refreshing | 是否处于刷新状态 | Boolean | false |
| pullingText | 下拉过程的提示文案 | String | 下拉刷新 |
| loosingText | 释放过程的提示文案 | String | 手指释放刷新 |
| refreshingText | 刷新过程的提示文案 | String | 刷新中... |
| successText | 刷新成功的提示文案 | String | 刷新成功 |
| successDuration | 刷新成功提示展示时长(ms) | Number | 0 |
| color | 提示文案的颜色 | String | #000 |
| size | 提示文案的字体大小 | Number或String | 28 |

### event
| 事件名 | 说明 | 回调参数 |
| --- | --- | --- |
| ready | better-scroll初始化完成时触发 | 当前better-scroll对象 |
| scroll | 页面滚动时触发 | "{x: 当前x轴滚动距离, y: 当前y轴滚动距离}" |
| load | 上拉加载时触发 | - |
| refresh | 下拉刷新时触发 | - |

### slots
| 名称 | 说明 | 参数 |
| --- | --- | --- |
| pulling | 下拉过程提示内容 | - |
| loosing | 释放过程顶部内容 | - |
| refreshing | 刷新过程提示内容 | - |
| success | 刷新成功提示内容 | - |
| loadingBefore | 上拉过程提示内容 | - |
| loading | 加载过程提示内容 | - |
| finished | 加载完成提示内容 | - |