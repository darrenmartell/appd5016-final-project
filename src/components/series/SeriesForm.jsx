import { useForm, useFieldArray } from "react-hook-form";
import { useParams, useNavigate, useOutletContext } from 'react-router-dom';
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { useAuthContext } from '../../context/AuthContext';
import { useState, useEffect } from "react";
import config from '../../config';

const inputClass =
  "w-full bg-zinc-800 border border-zinc-700 text-white px-3 py-2 text-sm focus:outline-none focus:border-red-700 transition-colors placeholder:text-zinc-400";
const labelClass = "block text-[10px] uppercase tracking-[0.2em] text-zinc-300 mb-1 font-medium";
const sectionClass = "border border-zinc-800 p-5 bg-zinc-900 rounded-lg";

const TagInput = ({ name, control, label, placeholder }) => {
  const { fields, append, remove } = useFieldArray({ control, name });
  const [inputVal, setInputVal] = useState("");

  const add = () => {
    const v = inputVal.trim();
    if (v) { append({ value: v }); setInputVal(""); }
  };

  return (
    <div>
      <label className={labelClass}>{label}</label>
      <div className="flex gap-2 mb-2">
        <input
          className={inputClass + " flex-1"}
          value={inputVal}
          onChange={(e) => setInputVal(e.target.value)}
          onKeyDown={(e) => { if (e.key === "Enter") { e.preventDefault(); add(); } }}
          placeholder={placeholder}
        />
        <button
          type="button"
          onClick={add}
          className="px-3 py-2 bg-[#e50914] text-[#fff] text-xs font-bold tracking-widest uppercase hover:bg-[#b20710] transition-colors"
        >
          +
        </button>
      </div>
      {fields.length > 0 && (
        <div className="flex flex-wrap gap-1">
          {fields.map((field, i) => (
            <span key={field.id} className="inline-flex items-center gap-1 px-2 py-1 bg-[#333] border border-[#444] text-[#fff] text-xs">
              {field.value}
              <button type="button" onClick={() => remove(i)} className="text-[#e50914] hover:text-[#ff6b6b] ml-1 leading-none">×</button>
            </span>
          ))}
        </div>
      )}
    </div>
  );
};

export default function SeriesForm({ editable }) {
  const queryClient = useQueryClient()
  const { token } = useAuthContext();
  const navigate = useNavigate();

  const { series } = useOutletContext();
  const { id } = useParams()

  const defaultValues = {
    title: "",
    plot_summary: "",
    runtime_minutes: "",
    released_year: "",
    cast: [],
    directors: [],
    genres: [],
    countries: [],
    languages: [],
    producers: [],
    production_companies: [],
    ratings: { imdb: "", rotten_tomatoes: "", metacritic: "", user_average: "" },
    episodes: [],
  };

  const { 
    register, 
    control, 
    handleSubmit, 
    formState: { errors, isSubmitting, isDirty }, 
    reset
  } = useForm({ defaultValues });

  const { fields: episodeFields, append: appendEpisode, remove: removeEpisode } = useFieldArray({
    control,
    name: "episodes",
  });

  // When series data is loaded or id changes, populate the form with current series data
  useEffect(() => {
    const current = series.find(s => s._id === id);
    if (current && editable) {
      reset({
        title: current.title,
        plot_summary: current.plot_summary,
        runtime_minutes: current.runtime_minutes,
        released_year: current.released_year,
        cast: (current.cast || []).map(c => ({ value: c })),
        directors: (current.directors || []).map(d => ({ value: d })),
        genres: (current.genres || []).map(g => ({ value: g })),
        countries: (current.countries || []).map(c => ({ value: c })),
        languages: (current.languages || []).map(l => ({ value: l })),
        producers: (current.producers || []).map(p => ({ value: p })),
        production_companies: (current.production_companies || []).map(pc => ({ value: pc })),
        ratings: {
          imdb: current.ratings?.imdb || "",
          rotten_tomatoes: current.ratings?.rotten_tomatoes || "",
          metacritic: current.ratings?.metacritic || "",
          user_average: current.ratings?.user_average || ""
        },
        episodes: [current.episodes || []].flat().sort((a, b) => a.episode_number - b.episode_number).map(ep => ({
          episode_number: ep.episode_number,
          episode_title: ep.episode_title,
          runtime_minutes: ep.runtime_minutes,
        })),
      });
    }
  }, [series, id, reset, editable]);

  const mutation = useMutation({
    mutationFn: async data => {
      const response = await fetch(
        editable ? `${config.API_URL}/series/${id}` : `${config.API_URL}/series`,
        {
          method: editable ? 'PUT' : 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify(data)
        })
      return response.json()
    },
    onSuccess: () => {
      console.log('mutation was successful')
      queryClient.invalidateQueries({ queryKey: ["seriesCache"] })
      navigate('/admin/series')
    },
    onError: () => {
      console.error('mutation error')
    }
  })

  const onSubmit = (data) => {
    // Flatten tag arrays back to string arrays
    const flatten = (arr) => (arr || []).map((item) => item.value);
    const processed = {
      ...data,
      runtime_minutes: Number(data.runtime_minutes),
      released_year: Number(data.released_year),
      cast: flatten(data.cast),
      directors: flatten(data.directors),
      genres: flatten(data.genres),
      countries: flatten(data.countries),
      languages: flatten(data.languages),
      producers: flatten(data.producers),
      production_companies: flatten(data.production_companies),
      ratings: {
        imdb: data.ratings.imdb !== "" ? Number(data.ratings.imdb) : null,
        rotten_tomatoes: data.ratings.rotten_tomatoes !== "" ? Number(data.ratings.rotten_tomatoes) : null,
        metacritic: data.ratings.metacritic !== "" ? Number(data.ratings.metacritic) : null,
        user_average: data.ratings.user_average !== "" ? Number(data.ratings.user_average) : null,
      },
      episodes: data.episodes.map((ep, i) => ({
        episode_number: i + 1,
        episode_title: ep.episode_title,
        runtime_minutes: Number(ep.runtime_minutes),
      })),
    };

    mutation.mutate(processed)  // triggers the mutation call
  };

  return (
    <div
      className="min-h-screen bg-[#141414] text-[#b3b3b3] p-6 md:p-10"
    >
      {/* Header */}
      <div className="mb-10 border-b border-[#333] pb-6">
        {/* <div className="text-[10px] uppercase tracking-[0.4em] text-[#e30022] mb-2">Netflix Series Database</div> */}
        <h1 className="text-4xl font-light text-[#fff] tracking-wide">
          {editable ? "Edit Series" : "Add Series"}
        </h1>
      </div>

      <form onSubmit={handleSubmit(onSubmit)} className="space-y-6 max-w-4xl">

        {/* Core Info */}
        <div className={sectionClass}>
          <div className="text-[10px] uppercase tracking-[0.3em] text-[#555] mb-4">Core Information</div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="md:col-span-2">
              <label className={labelClass}>Title *</label>
              <input className={inputClass} {...register("title", { required: true })} placeholder="Series title" />
              {errors.title && <p className="text-[#ff6b6b] text-xs mt-1">Required</p>}
            </div>
            <div className="md:col-span-2">
              <label className={labelClass}>Plot Summary</label>
              <textarea
                className={inputClass + " resize-none"}
                rows={3}
                {...register("plot_summary")}
                placeholder="Brief synopsis..."
              />
            </div>
            <div>
              <label className={labelClass}>Runtime (minutes)</label>
              <input type="number" className={inputClass} {...register("runtime_minutes")} placeholder="e.g. 384" />
            </div>
            <div>
              <label className={labelClass}>Released Year</label>
              <input type="number" className={inputClass} {...register("released_year")} placeholder="e.g. 2024" />
            </div>
          </div>
        </div>

        {/* People */}
        <div className={sectionClass}>
          <div className="text-[10px] uppercase tracking-[0.3em] text-[#555] mb-4">People</div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <TagInput control={control} name="cast" label="Cast" placeholder="Actor name, press Enter or +" />
            <TagInput control={control} name="directors" label="Directors" placeholder="Director name" />
            <TagInput control={control} name="producers" label="Producers" placeholder="Producer name" />
          </div>
        </div>

        {/* Production */}
        <div className={sectionClass}>
          <div className="text-[10px] uppercase tracking-[0.3em] text-[#555] mb-4">Production</div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-5">
            <TagInput control={control} name="production_companies" label="Production Companies" placeholder="Company name" />
            <TagInput control={control} name="countries" label="Countries" placeholder="e.g. United Kingdom" />
            <TagInput control={control} name="languages" label="Languages" placeholder="e.g. English" />
            <TagInput control={control} name="genres" label="Genres" placeholder="e.g. Thriller" />
          </div>
        </div>

        {/* Ratings */}
        <div className={sectionClass}>
          <div className="text-[10px] uppercase tracking-[0.3em] text-[#555] mb-4">Ratings</div>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {[
              { key: "imdb", label: "IMDb", placeholder: "0.0 – 10.0" },
              { key: "rotten_tomatoes", label: "Rotten Tomatoes", placeholder: "0 – 100" },
              { key: "metacritic", label: "Metacritic", placeholder: "0 – 100" },
              { key: "user_average", label: "User Average", placeholder: "0.0 – 10.0" },
            ].map(({ key, label, placeholder }) => (
              <div key={key}>
                <label className={labelClass}>{label}</label>
                <input
                  type="number"
                  step="0.1"
                  className={inputClass}
                  {...register(`ratings.${key}`)}
                  placeholder={placeholder}
                />
              </div>
            ))}
          </div>
        </div>

        {/* Episodes */}
        <div className={sectionClass}>
          <div className="flex items-center justify-between mb-4">
            <div className="text-[10px] uppercase tracking-[0.3em] text-[#555]">Episodes</div>
            <button
              type="button"
              onClick={() => appendEpisode({ episode_number: "", episode_title: "", runtime_minutes: "" })}
              className="text-[10px] uppercase tracking-[0.2em] text-[#b3b3b3] border border-[#444] px-3 py-1 hover:bg-[#e50914] hover:text-[#fff] hover:border-[#e50914] transition-colors"
            >
              + Add Episode
            </button>
          </div>

          {episodeFields.length === 0 && (
            <div className="text-center py-8 text-[#888] text-xs uppercase tracking-widest border border-dashed border-[#333]">
              No episodes added yet
            </div>
          )}

          <div className="space-y-2">
            {episodeFields.map((field, i) => (
              <div key={field.id} className="flex items-center gap-3 bg-[#222] border border-[#333] p-3">
                <div className="grid grid-cols-12 gap-4 items-end" >
                  <div className="col-span-2">
                    <label className={labelClass}>Episode #</label>
                    <input
                      type="number"
                      className={inputClass + " flex-1"}
                      {...register(`episodes.${i}.episode_number`)}
                      placeholder="Episode number"
                    />
                  </div>
                  <div className="col-span-8">
                    <label className={labelClass}>Episode Title</label>
                    <input
                      className={inputClass + " flex-1"}
                      {...register(`episodes.${i}.episode_title`)}
                      placeholder="Episode title"
                    />
                  </div>
                  <div className="md:col-span-2">
                    <label className={labelClass}>Minutes</label>
                    <input
                      type="number"
                      className={inputClass + " w-24 shrink-0"}
                      {...register(`episodes.${i}.runtime_minutes`)}
                      placeholder="mins"
                    />
                  </div>

                </div>
                <button
                  type="button"
                  onClick={() => removeEpisode(i)}
                  className="text-[#555] hover:text-[#ff6b6b] transition-colors text-lg leading-none shrink-0 px-1"
                >
                  ×
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex gap-3 pt-2">
          <button
            type="submit"
            className="flex-1 py-3 bg-[#e50914] text-[#ffffff] text-xs font-bold uppercase tracking-[0.3em] hover:bg-[#b20710] transition-colors disabled:bg-[#333] disabled:text-[#666] disabled:cursor-not-allowed"
            disabled={isSubmitting || !isDirty}
          >
            {editable ? "Update Series" : "Add Series"}
          </button>
          <button
            type="button"
            onClick={() => navigate(-1)}
            className="px-8 py-3 bg-[#333] text-[#b3b3b3] border border-[#444] font-bold text-xs uppercase tracking-[0.3em] hover:bg-[#444] hover:text-[#fff] transition-colors"
          >
            ← Back
          </button>
        </div>
      </form>
    </div>
  );
}