using Test
if !isdefined(Main, :N02NonlinearAdvection)
    include(joinpath(@__DIR__, "run.jl"))
end
@testset "N02 必須テスト" begin
    # TODO(必須): 異なる流束の手計算値、先頭と先頭以外の周期左隣添字を確認する。
    @test false
    # TODO(必須): 非定数の小配列を選び、保存形1ステップの配列全体を手計算と比較する。旧配列も不変か確かめる。
    @test false
    # TODO(必須): 固定の定数1、周期の別の非負定数が保たれることと、固定左右境界の配列全体を確認する。
    @test false
    # TODO(必須): 固定・周期のCFLと有界性、一定速度の平行移動とは異なる波形変形を確かめる。判定量と条件の根拠を学習ログに書く。
    @test false
end
@testset "N02 自作テスト" begin
    # TODO(自作): 周期の非定数・非負配列を複数ステップ進め、離散総和保存を確認する。入力・許容誤差・期待値を自分で決める。
    @test false
    # TODO(自作): 周期1ステップSについてS(circshift(u,k)) ≈ circshift(S(u),k)を確認する。非対称な非定数配列、k≠0、同じdtとdxを使う。
    @test false
end
