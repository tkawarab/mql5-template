## 概要
MetaQuotes社によって開発されているトレードプラットフォーム「MetaTrader5」（以下MT5）上で動作するExpertAdvisor（以下EA）のプログラムです。

EAは基本的なライフサイクルイベント（初期化、終了、ティックデータの処理、取引の処理、テスト結果の取得）を処理し、ストラテジーのロジックに基づきトレード活動を実行します。

## 目的
本EAの目的はMT5で動作するEAを開発するためのテンプレートを提供します。

様々な戦略のEAを開発効率を上げるためにオブジェクト指向プログラミング（以下OOP）を取り入れ、共通処理をクラス化し、それらを呼び出し使用することによって、戦略に必要な部分の開発のみに集中することができます。

これにより共通で必要なコードの記述・管理することなくEAを量産できるため、迅速にトレードアイデアを形にし、様々なEA開発効率の向上を期待できます。

## 前提知識
本プログラムを扱うために必要な前提知識は以下の通り

- 株式・外国為替証拠金取引（FX）・CFD等のトレード知識
- MT5の使用
- MQL5のコード記述・コンパイル・デバッグ
- OOPの理解と実装経験

## 使用方法
トレード戦略ごとにExperts/Template.mq5ファイルを別名コピーし、
既定クラスのメソッドに戦略のロジックを記述するだけで、EAを開発することができます。

## 各ディレクトリの説明
### Experts ディレクトリ
- EAの本体であり戦略を記述するファイルが格納されています
別名でコピーして使用します（以下Expertsファイル）
- Expertファイル内のStrategy段落より下の「CMyExpertStrategy」クラスに戦略を記述して使用します
　以下メソッドの説明
    - InitIndicatorメソッド
        - 戦略で使用するインディケーターの初期化を行います
        　OnInitイベントで呼び出されます
    - RefreshIndicatorメソッド
        - インディケーターの値を更新します
        　OnTickイベントで呼び出されます
    - CheckOpenメソッド
        - エントリーを行うかどうかを判断するロジックを記述します
    - CheckCloseメソッド
        - 保有中ポジションのエグジットを行うかどうかを判断するロジックを記述します
　※ただし、ロジックを必要とせずTakeProfitやStoploss、経過バー数によるエグジットなど予め共通処理として用意されている機能を使用することができるためそれらの処理は記述が不要です
　使用できる機能はEAのインプットパラメータを確認してください



### Include/Custom ディレクトリ
- 共通処理が記述されているライブラリ群が格納されています
- 特定の共通機能に変更を必要としない限りこのライブラリ群を編集する必要はありません
- Customディレクトリ配下のディレクトリ
#### com
- EA基幹部分の処理が記述されたファイル群が格納されています
- Input.mqhにEAインプットパラメータが記述されています
　戦略に必要なパラメータはExpertsファイルに記述をしてください
#### extlib
- 外部定義の共通関数ファイルが格納されています
#### lib
- 共通関数ファイルが格納されています
#### mqlib
- mql5標準クラスをカスタムしたファイルが格納されています
#### tester
- ストラテジーテスターで呼び出される分析用ファイルが格納されています

### ライセンス
```
The MIT License (MIT)

Copyright (c) 2015-2024 tkawarab

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```