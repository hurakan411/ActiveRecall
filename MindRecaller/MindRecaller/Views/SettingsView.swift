import SwiftUI

struct SettingsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // アプリについてセクション
                VStack(alignment: .leading, spacing: 14) {
                    Text("アプリについて")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                    
                    VStack(spacing: 0) {
                        NavigationLink(destination: TermsOfServiceView()) {
                            HStack {
                                Text("利用規約")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(AppColors.surface)
                        }
                        
                        Divider()
                            .background(AppColors.border)
                            .padding(.horizontal, 16)
                        
                        NavigationLink(destination: PrivacyPolicyView()) {
                            HStack {
                                Text("プライバシーポリシー")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            .padding(.vertical, 16)
                            .padding(.horizontal, 16)
                            .background(AppColors.surface)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                
                // 言語設定セクション
                VStack(alignment: .leading, spacing: 14) {
                    Text("言語 / Language")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppColors.textSecondary)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                    
                    VStack(spacing: 0) {
                        LanguagePickerRow()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.border, lineWidth: 1)
                    )
                }
                
                // その他の情報セクション
                VStack(spacing: 0) {
                    HStack {
                        Text("バージョン")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textPrimary)
                        Spacer()
                        Text("1.0.0")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.textSecondary)
                    }
                    .padding(.vertical, 16)
                    .padding(.horizontal, 16)
                    .background(AppColors.surface)
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(AppColors.border, lineWidth: 1)
                )
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LanguagePickerRow: View {
    @AppStorage("appLanguage") private var appLanguage: AppLanguage = .system
    
    var body: some View {
        HStack {
            Text("アプリの言語")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Spacer()
            Picker("言語", selection: $appLanguage) {
                ForEach(AppLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.menu)
            .tint(AppColors.textSecondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(AppColors.surface)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("利用規約")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 8)
                
                Text("""
この利用規約（以下、「本規約」といいます）は、スマートフォン向けアプリケーション「アクリコ | AI Active Recall」（以下、「本アプリ」といいます）の提供条件およびアプリを利用するユーザー（以下、「ユーザー」といいます）と開発者との間の権利義務関係を定めるものです。
本アプリをご利用になる際は、本規約に同意していただく必要があります。

第1条（適用）
本規約は、ユーザーと開発者との間の本アプリの利用に関わる一切の関係に適用されるものとします。

第2条（機能について）
本アプリは、ユーザーが撮影・入力した画像やテキストデータを元に、AI（Google Gemini API 等）を利用してテキストの抽出、採点、フィードバック等の学習支援機能を提供します。
AIが生成または抽出した結果の正確性、完全性、および特定の学習目的に対する有用性について、開発者は一切の保証を行いません。

第3条（禁止事項）
ユーザーは、本アプリの利用にあたり、以下の行為を行ってはなりません。
1. 第3者の著作権、商標権、プライバシー権、肖像権等の権利を侵害する行為（例: 著作権法で認められる私的利用の範囲を超えて、市販の書籍などを無断で撮影・アップロード・利用する行為）
2. 公序良俗に反する行為、または犯罪行為に関連する行為
3. 開発者、他のユーザー、またはその他の第三者に不利益、損害、不快感を与える行為
4. 本アプリのネットワークまたはシステム等に過度な負荷をかける行為
5. リバースエンジニアリングその他の解析行為
6. その他、開発者が不適切と判断する行為

第4条（利用制限およびサービスの停止）
開発者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく本アプリの全部または一部の提供を停止または中断することができるものとします。
1. 本アプリにかかるコンピュータシステムの保守点検または更新を行う場合
2. 連携する外部API（Google Gemini API 等）に障害や利用制限（レートリミットなど）が発生した場合
3. 地震、落雷、火災、停電または天災などの不可抗力により、本アプリの提供が困難となった場合
4. その他、開発者が本アプリの提供が困難と判断した場合

また、ユーザーが本規約のいずれかに違反した場合、事前の通知なくユーザーに対して本アプリの利用を制限することができるものとします。

第5条（免責事項）
1. 開発者は、本アプリに事実上または法律上の瑕疵（安全性、信頼性、正確性、完全性、有効性、特定の目的への適合性、セキュリティなどに関する欠陥、エラーやバグ、権利侵害などを含みます）がないことを明示的にも黙示的にも保証しておりません。
2. 開発者は、本アプリに関連してユーザーに生じたあらゆる損害について一切の責任を負いません。

第6条（規約の変更）
開発者は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。変更後の利用規約は、本アプリ内または関連サイトに掲示された時点から効力を生じるものとし、ユーザーはこれに同意したものとみなします。

第7条（準拠法・裁判管轄）
本規約の解釈にあたっては、日本法を準拠法とします。本アプリに関して紛争が生じた場合には、開発者の所在地を管轄する裁判所を専属的合意管轄とします。

制定日: 2026年4月14日
""")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(4)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("プライバシーポリシー")
                    .font(.system(size: 24, weight: .bold))
                    .padding(.bottom, 8)
                
                Text("""
本プライバシーポリシーは、スマートフォン向け学習支援アプリケーション「アクリコ | AI Active Recall」（以下、「本アプリ」といいます）において、ユーザーの皆様の情報をどのように取り扱うかを定めたものです。

1. 取得する情報とその利用目的
本アプリは、以下の情報を取得し、それぞれの目的のために利用します。

【画像データおよびテキストデータ】
内容: ユーザーが教材登録のために撮影・選択した画像、ならびに入力したテキスト（ソーステキスト、また想起採点プロセスのために入力したリコールテキスト）。
利用目的: AIモデル（外部サービス）を利用したテキスト抽出、教材の要約・生成、および学習の採点・分析・フィードバックを提供するため。

【学習履歴データ】
内容: 学習回数、採点スコア、タグ情報などのアプリ内での活動履歴。
利用目的: アプリ内における成績の表示、ユーザーの学習状況にあわせた体験の最適化のため。

※ ユーザー自身で入力した学習内容や成績などのデータ（SwiftData等を利用して保存されるもの）は、ユーザーの端末内にのみローカル保存され、開発者が直接閲覧・収集することはありません。

2. 外部API・第三者提供について
本アプリは、中核となるAI機能（テキスト抽出、採点システム等）を提供するため、ユーザーが入力した画像データやテキストデータを、本アプリのバックエンドサーバーを経由してGoogleの提供するGemini API（Google LLC）へ送信します。

- 送信されたデータは、該当APIにおける解析プロセスのみを目的として機械的に処理されます。
- 当該通信ならびにAI処理に関するデータの取り扱いは、Googleのプライバシー要件に従います。
- ユーザーの明示的な同意がある場合や法令に基づく場合を除き、これ以外の目的で第三者へ個人情報や学習データを販売・提供することはありません。

3. 免責事項
本アプリの利用により生じたトラブルや損害に関して、開発者は一切の責任を負いません。また、AI処理によるテキスト抽出や採点結果は、その正確性や完全性を100%保証するものではありません。

4. プライバシーポリシーの変更
開発者は、法令の変更や本アプリの機能追加・修正に伴い、事前の通知なく本プライバシーポリシーを変更することがあります。重要な変更がある場合は、アプリ内などの適切な方法でお知らせします。

5. お問い合わせ
本アプリのプライバシーポリシーに関するお問い合わせは、各ストアのサポートページまたは開発者の連絡先までお願いいたします。

制定日: 2026年4月14日
""")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .lineSpacing(4)
            }
            .padding(20)
        }
        .background(AppColors.background)
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}
